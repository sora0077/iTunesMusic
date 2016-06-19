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
}

protocol PlaylistTypeInternal: PlaylistType {
    
    associatedtype RealmElement: Object
    
    var objects: List<RealmElement> { get }
    
    func track(atIndex index: Int) -> Track
}


//extension PlaylistTypeInternal where Self: CollectionType {
//    
//    var startIndex: Int { return objects.startIndex }
//    
//    var endIndex: Int { return objects.endIndex }
//    
//    subscript (index: Int) -> Element { return objects[index] }
//}
