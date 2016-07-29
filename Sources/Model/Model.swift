//
//  Model.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Timepiece


public struct Model {}


//MARK: - CollectionChange
public enum CollectionChange {
    case initial
    case update(deletions: [Int], insertions: [Int], modifications: [Int])

    init<T>(_ change: RealmCollectionChange<T>) {

        switch change {
        case .Initial:
            self = .initial
        case let .Update(_, deletions: deletions, insertions: insertions, modifications: modifications):
            self = .update(deletions: deletions, insertions: insertions, modifications: modifications)
        case let .Error(error):
            fatalError("\(error)")
        }
    }
}

//MARK: - RequestState
public enum RequestState: Int {
    case none, requesting, error, done
}

//MARK: - ObservableList
protocol _ObservableList: class {

    var _changes: PublishSubject<CollectionChange> { get }
}

private struct _ObservableListKey {
    static var _changes: UInt8 = 0
}

extension _ObservableList {

    var _changes: PublishSubject<CollectionChange> {
        if let change = objc_getAssociatedObject(self, &_ObservableListKey._changes) as? PublishSubject<CollectionChange> {
            return change
        }
        let change = PublishSubject<CollectionChange>()
        objc_setAssociatedObject(self, &_ObservableListKey._changes, change, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return change
    }

}

//MARK: - Fetchable
public protocol Fetchable {

    var requestState: Observable<RequestState> { get }

    func fetch()

    func refresh()

    func refresh(force: Bool)
}

protocol _Fetchable: class, Fetchable {

    var _requestState: Variable<RequestState> { get }

    var _refreshAt: Date { get }

    var _refreshDuration: Duration { get }

    var needRefresh: Bool { get }

    var hasNoPaginatedContents: Bool { get }

    func request(refreshing: Bool, force: Bool)
}

extension Fetchable {

    public func fetch() {
        guard Thread.isMainThread else {
            defer {
                DispatchQueue.main.async {
                    self.fetch()
                }
            }
            return
        }
        _request(refreshing: false, force: false)
    }

    public func refresh() {
        refresh(force: false)
    }

    public func refresh(force: Bool) {
        guard Thread.isMainThread else {
            defer {
                DispatchQueue.main.async {
                    self.refresh(force: force)
                }
            }
            return
        }
        // swiftlint:disable force_cast
        let s = self as! _Fetchable
        if force || s.needRefresh {
            _request(refreshing: true, force: force)
        }
    }

    private func _request(refreshing: Bool, force: Bool) {
        // swiftlint:disable force_cast
        let s = self as! _Fetchable
        if [.done, .requesting].contains(s._requestState.value) {
            return
        }

        print("now request, \(self)")

        s._requestState.value = .requesting

        s.request(refreshing: refreshing, force: force)
    }
}

private struct _FetchableKey {
    static var _requestState: UInt8 = 0
}

extension _Fetchable {

    var needRefresh: Bool {
        return Date() - _refreshAt > _refreshDuration
    }

    var _requestState: Variable<RequestState> {
        if let state = objc_getAssociatedObject(self, &_FetchableKey._requestState) as? Variable<RequestState> {
            return state
        }
        let state = Variable<RequestState>(.none)
        objc_setAssociatedObject(self, &_FetchableKey._requestState, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }

    var hasNoPaginatedContents: Bool {
        return [.done, .error].contains(_requestState.value)
    }
}
