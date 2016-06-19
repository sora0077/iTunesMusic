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



public enum RequestState: Int {
    case None, Requesting, Error, Done
}

class AnyPlaylist<RealmElement: RealmSwift.Object>: PlaylistTypeInternal, PlaylistType, CollectionType {
    
    var objects: AnyRealmCollection<RealmElement> { return AnyRealmCollection(base.objects) }
    
    var changes: Observable<CollectionChange> { return base.changes }
    
    subscript (index: Int) -> Track { return base[index] }
//    var paginated: Bool { return base.paginated }
    
    private let base: _AnyPlaylistBase<RealmElement>
    
    init<Playlist: PlaylistTypeInternal where Playlist.RealmElement == RealmElement>(playlist: Playlist) {
        base = _AnyPlaylist(playlist: playlist)
    }
    
    func addInto(player player: Player) {
        fatalError()
    }
}

class AnyPaginatedPlaylist<RealmElement: RealmSwift.Object>: AnyPlaylist<RealmElement>, PaginatorTypeInternal {
    
    var requestState: Observable<RequestState> { return base.requestState }
    
    func fetch() { base.fetch() }
    
    func refresh(force force: Bool) { base.refresh(force: force) }
    
    var hasNoPaginatedContents: Bool { return base.hasNoPaginatedContents }
    
    override init<Playlist: protocol<PlaylistTypeInternal, PaginatorTypeInternal> where Playlist.RealmElement == RealmElement>(playlist: Playlist) {
        super.init(playlist: playlist)
    }
}

extension AnyPlaylist {
    
    var startIndex: Int { return base.startIndex }
    
    var endIndex: Int { return base.endIndex }
    
//    subscript (index: Int) -> RealmElement { return base[index] }
}


private class _AnyPlaylistBase<RealmElement: RealmSwift.Object>: PlaylistTypeInternal, CollectionType {
    
//    typealias Index = List<Element>.Index
    
    private var objects: AnyRealmCollection<RealmElement> { fatalError() }
    
    private var changes: Observable<CollectionChange> { fatalError() }
    
//    private var paginated: Bool { fatalError() }
    
    private var requestState: Observable<RequestState> { fatalError() }
    
    var hasNoPaginatedContents: Bool { fatalError() }
    
    subscript (index: Int) -> Track { fatalError() }
    
    
    private func fetch() { fatalError() }
    
    private func refresh(force force: Bool) { fatalError() }
    
    private func addInto(player player: Player) { fatalError() }
}

extension _AnyPlaylistBase {
    
    private var startIndex: Int { return objects.startIndex }
    
    private var endIndex: Int { return objects.endIndex }
    
//    subscript (index: Int) -> RealmElement { return objects[index] }
}


private class _AnyPlaylist<Playlist: PlaylistTypeInternal>: _AnyPlaylistBase<Playlist.RealmElement> {
    
    typealias RealmElement = Playlist.RealmElement
    
    private let base: Playlist
    
    private override var objects: AnyRealmCollection<RealmElement> { return AnyRealmCollection(base.objects) }
    
    private override var changes: Observable<CollectionChange> { return base.changes }
    
    
    private override subscript (index: Int) -> Track { return base[index] }
//    private override var paginated: Bool { return base.paginated }
    
    init(playlist: Playlist) {
        base = playlist
        
        super.init()
    }
    
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
