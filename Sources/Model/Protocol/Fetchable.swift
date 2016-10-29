//
//  Fetchable.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import Timepiece
import ErrorEventHandler


//MARK: - Fetchable
public protocol Fetchable: class {

    var requestState: Observable<RequestState> { get }

    func fetch(ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level)

    func refresh(ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level)

    func refresh(force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level)
}

private struct FetchableKey {
    static var requestState: UInt8 = 0
}

extension Fetchable {

    public var requestState: Observable<RequestState> {
        // swiftlint:disable force_cast
        return associatedObject(self, &FetchableKey.requestState,
                                initial: asObservable((self as! _Fetchable)._requestState).distinctUntilChanged())
    }

    public func fetch(ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level) {
        fetch(ifError: errorType, level: level, completion: { _ in })
    }

    func fetch(ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (Swift.Error?) -> Void) {
        guard doOnMainThread(execute: self.fetch(ifError: errorType, level: level, completion: completion)) else {
            return
        }
        _request(refreshing: false, force: false, ifError: errorType, level: level, completion: completion)
    }

    public func refresh(ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level) {
        refresh(force: false, ifError: errorType, level: level)
    }

    public func refresh(force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level) {
        guard doOnMainThread(execute: self.refresh(force: force, ifError: errorType, level: level)) else {
            return
        }
        // swiftlint:disable force_cast
        let `self` = self as! _Fetchable
        if force || self._needRefresh {
            _request(refreshing: true, force: force, ifError: errorType, level: level)
        }
    }

    private func _request(refreshing: Bool, force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (Swift.Error?) -> Void = { _ in }) {
        // swiftlint:disable force_cast
        let `self` = self as! _Fetchable
        if !force && [.done, .requesting].contains(self._requestState.value) {
            return
        }

        print("now request, \(self)")

        self._requesting.value = true
        self._refreshing.value = refreshing
        self._requestState.value = .requesting

        self.request(refreshing: refreshing, force: force, ifError: errorType, level: level) { [weak self] requestState in
            DispatchQueue.main.async {
                self?._requesting.value = false
                self?._refreshing.value = false
                self?._requestState.value = requestState
                if case .error(let error) = requestState {
                    ErrorLog.enqueue(error: error, with: errorType, level: level)
                    completion(error)
                } else {
                    completion(nil)
                }
                tick()
            }
        }
    }
}

//MARK: - _Fetchable

protocol _Fetchable: class, Fetchable {

    var _refreshing: Variable<Bool> { get }

    var _requesting: Variable<Bool> { get }

    var _requestState: Variable<RequestState> { get }

    var _refreshAt: Date { get }

    var _refreshDuration: Duration { get }

    var _needRefresh: Bool { get }

    var _hasNoPaginatedContents: Bool { get }

    func request(refreshing: Bool, force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (RequestState) -> Void)
}

private struct _FetchableKey {
    static var _refreshing: UInt8 = 0
    static var _requesting: UInt8 = 0
    static var _requestState: UInt8 = 0
}

extension _Fetchable {

    var _needRefresh: Bool {
        return Date() - _refreshAt > _refreshDuration
    }

    var _refreshing: Variable<Bool> {
        return associatedObject(self, &_FetchableKey._refreshing, initial: Variable(false))
    }

    var _requesting: Variable<Bool> {
        return associatedObject(self, &_FetchableKey._requesting, initial: Variable(false))
    }

    var _requestState: Variable<RequestState> {
        return associatedObject(self, &_FetchableKey._requestState, initial: Variable(.none))
    }

    var _hasNoPaginatedContents: Bool {
        switch _requestState.value {
        case .error, .done:
            return true
        default:
            return false
        }
    }
}
