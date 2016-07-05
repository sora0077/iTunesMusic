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
    
    func refresh(force force: Bool)
}

protocol FetchableInternal: Fetchable {
    
    var _requestState: Variable<RequestState> { get }
    
    var needRefresh: Bool { get }
    
    var hasNoPaginatedContents: Bool { get }
    
    func request(refreshing refreshing: Bool)
}

extension Fetchable {
    
    public func fetch() {
        _request(refreshing: false)
    }
    
    public func refresh(force force: Bool) {
        let s = self as! FetchableInternal
        if force || s.needRefresh {
            _request(refreshing: true)
        }
    }
    
    private func _request(refreshing refreshing: Bool) {
        let s = self as! FetchableInternal
        if [.done, .requesting].contains(s._requestState.value) {
            return
        }
        
        s._requestState.value = .requesting
        
        s.request(refreshing: refreshing)
    }
}

extension FetchableInternal {
    
    var hasNoPaginatedContents: Bool {
        return [.done, .error].contains(_requestState.value)
    }
}
