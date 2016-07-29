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


public struct Model {}


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


public enum RequestState: Int {
    case none, requesting, error, done
}


public protocol Fetchable {

    var requestState: Observable<RequestState> { get }

    func fetch()

    func refresh()

    func refresh(force: Bool)
}

protocol FetchableInternal: Fetchable {

    var _requestState: Variable<RequestState> { get }

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
        let s = self as! FetchableInternal
        if force || s.needRefresh {
            _request(refreshing: true, force: force)
        }
    }

    private func _request(refreshing: Bool, force: Bool) {
        // swiftlint:disable force_cast
        let s = self as! FetchableInternal
        if [.done, .requesting].contains(s._requestState.value) {
            return
        }

        print("now request, \(self)")

        s._requestState.value = .requesting

        s.request(refreshing: refreshing, force: force)
    }
}

extension FetchableInternal {

    var hasNoPaginatedContents: Bool {
        return [.done, .error].contains(_requestState.value)
    }
}
