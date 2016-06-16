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
    
    var count: Int { get }
    
    var changes: Observable<CollectionChange> { get }
    
    func track(atIndex index: Int) -> Track
    
    func addInto(player player: Player)
}

protocol PlaylistTypeInternal: PlaylistType {
    
    associatedtype Element: Object
    
    var objects: List<Element> { get }

//    var createAt: NSDate { get }
//    var updateAt: NSDate { get }
}

extension PlaylistTypeInternal where Self: CollectionType {
    
    var startIndex: Int { return objects.startIndex }
    
    var endIndex: Int { return objects.endIndex }
    
    subscript (index: Int) -> Element { return objects[index] }
}

class AnyPlaylist<Element: RealmSwift.Object>: PlaylistTypeInternal, PlaylistType, CollectionType {
    
    var objects: List<Element> { return base.objects }
    
    var changes: Observable<CollectionChange> { return base.changes }
    
//    var paginated: Bool { return base.paginated }
    
    private let base: _AnyPlaylistBase<Element>
    
    init<Playlist: PlaylistTypeInternal where Playlist.Element == Element>(playlist: Playlist) {
        base = _AnyPlaylist(playlist: playlist)
    }
    
    func track(atIndex index: Int) -> Track {
        return base.track(atIndex: index)
    }
    
    func addInto(player player: Player) {
        fatalError()
    }
}

class AnyPaginatedPlaylist<Element: RealmSwift.Object>: AnyPlaylist<Element>, PaginatorTypeInternal {
    
    var requestState: Observable<RequestState> { return base.requestState }
    
    func fetch() { base.fetch() }
    
    func refresh(force force: Bool) { base.refresh(force: force) }
    
    var hasNoPaginatedContents: Bool { return base.hasNoPaginatedContents }
    
    override init<Playlist: protocol<PlaylistTypeInternal, PaginatorTypeInternal> where Playlist.Element == Element>(playlist: Playlist) {
        super.init(playlist: playlist)
    }
}

extension AnyPlaylist {
    
    var startIndex: Int { return base.startIndex }
    
    var endIndex: Int { return base.endIndex }
    
    subscript (index: Int) -> Element { return base[index] }
}


private class _AnyPlaylistBase<Element: RealmSwift.Object>: PlaylistTypeInternal, CollectionType {
    
//    typealias Index = List<Element>.Index
    
    private var objects: List<Element> { fatalError() }
    
    private var changes: Observable<CollectionChange> { fatalError() }
    
//    private var paginated: Bool { fatalError() }
    
    private var requestState: Observable<RequestState> { fatalError() }
    
    var hasNoPaginatedContents: Bool { fatalError() }
    
    
    private func track(atIndex index: Int) -> Track { fatalError() }
    
    
    private func fetch() { fatalError() }
    
    private func refresh(force force: Bool) { fatalError() }
    
    private func addInto(player player: Player) { fatalError() }
}

extension _AnyPlaylistBase {
    
    private var startIndex: Int { return objects.startIndex }
    
    private var endIndex: Int { return objects.endIndex }
    
    subscript (index: Int) -> Element { return objects[index] }
}


private class _AnyPlaylist<Playlist: PlaylistTypeInternal>: _AnyPlaylistBase<Playlist.Element> {
    
    typealias Element = Playlist.Element
    
    private let base: Playlist
    
    private override var objects: List<Element> { return base.objects }
    
    private override var changes: Observable<CollectionChange> { return base.changes }
    
//    private override var paginated: Bool { return base.paginated }
    
    init(playlist: Playlist) {
        base = playlist
        
        super.init()
    }
    
    private override func track(atIndex index: Int) -> Track {
        return base.track(atIndex: index)
    }
    
//}
//
//extension _AnyPlaylist where Playlist: PaginatorTypeInternal {
    
    private override var requestState: Observable<RequestState> { return (base as! PaginatorTypeInternal).requestState }

    private override var hasNoPaginatedContents: Bool { return (base as! PaginatorTypeInternal).hasNoPaginatedContents }
    
    private override func fetch() {
        (base as! PaginatorTypeInternal).fetch()
    }
    
    private override func refresh(force force: Bool) {
        (base as! PaginatorTypeInternal).refresh(force: force)
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
