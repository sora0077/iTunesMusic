//
//  PlaylistType.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/17.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift


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

public protocol PlaylistType: class {
    
    var changes: Observable<CollectionChange> { get }
    
    var count: Int { get }
    var isEmpty: Bool { get }
    
    subscript (index: Int) -> Track { get }
    
    /**
     Do not use
     */
    func _any() -> PlaylistType
}

extension PlaylistType {
    
    public func _any() -> PlaylistType { return self }
}

protocol PlaylistTypeInternal: PlaylistType {
    
    associatedtype RealmElement: Object
    
    var objects: AnyRealmCollection<RealmElement> { get }
}
