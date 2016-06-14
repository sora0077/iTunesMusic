//
//  AnyPlaylist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift


public enum CollectionChange {
    case Initial
    case Update(deletions: [Int], insertions: [Int], modifications: [Int])
    
    init<T>(_ change: RealmCollectionChange<T>) {
        
        switch change {
        case .Initial:
            self = .Initial
        case let .Update(_, deletions: deletions, insertions: insertions, modifications: modifications):
            self = .Update(deletions: deletions, insertions: insertions, modifications: modifications)
        case let .Error(error):
            fatalError("\(error)")
        }
    }
}

public enum RequestState: Int {
    case None, Requesting, Error, Done
}


public protocol PlaylistType: class {
    
    var name: String { get }
    
    var changes: Observable<CollectionChange> { get }
}

protocol PlaylistTypeInternal: PlaylistType {
    
    var objects: List<_Track> { get }
    
//    var createAt: NSDate { get }
//    var updateAt: NSDate { get }
}

extension PlaylistTypeInternal where Self: CollectionType {
    
    var startIndex: Int { return objects.startIndex }
    
    var endIndex: Int { return objects.endIndex }
    
    subscript (index: Int) -> Track {
        return objects[index] as Track
    }
}

public final class AnyPlaylist: PlaylistTypeInternal, PlaylistType {
    
    var objects: List<_Track> { return base.objects }
    
//    var createAt: NSDate { return base.createAt }
//    
//    var updateAt: NSDate { return base.updateAt }
    
    public var name: String { return base.name }
    
    public var changes: Observable<CollectionChange> { return base.changes }
    
    private let base: PlaylistTypeInternal
    
    init(playlist: PlaylistTypeInternal) {
        base = playlist
    }
}

public protocol PaginatorType {
    
    var requestState: Observable<RequestState> { get }
    
    func fetch()
    
    func refresh(force force: Bool)
}

protocol PaginatorTypeInternal: PaginatorType {
    
    var hasNoPaginatedContents: Bool { get }
}

public final class AnyPaginatedPlaylist: PlaylistType, PaginatorType {
    
    var objects: List<_Track> { return base.objects }
    
    public var name: String { return base.name }
    
    public var changes: Observable<CollectionChange> { return base.changes }
    
    public var requestState: Observable<RequestState> { return base.requestState }
    
    private let base: protocol<PlaylistTypeInternal, PaginatorType>
    
    init(playlist: protocol<PlaylistTypeInternal, PaginatorType>) {
        base = playlist
    }
    
    public func fetch() { base.fetch() }
    
    public func refresh(force force: Bool) { base.refresh(force: force) }
}

extension AnyPaginatedPlaylist: CollectionType {
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track {
        return objects[index] as Track
    }
}
