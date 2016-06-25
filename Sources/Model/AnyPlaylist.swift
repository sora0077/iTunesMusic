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
    case none, requesting, error, done
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
    
    func _any() -> PlaylistType { return base._any() }
}

class AnyPaginatedPlaylist<RealmElement: RealmSwift.Object>: AnyPlaylist<RealmElement>, Fetchable, FetchableInternal {
    
    var requestState: Observable<RequestState> { return base.requestState }
    
    var _requestState: Variable<RequestState> { return base._requestState }
    
    var needRefresh: Bool { return base.needRefresh }
    
    func request(refreshing refreshing: Bool) { base.request(refreshing: refreshing) }
    
    var hasNoPaginatedContents: Bool { return base.hasNoPaginatedContents }
    
    override init<Playlist: protocol<PlaylistTypeInternal, FetchableInternal> where Playlist.RealmElement == RealmElement>(playlist: Playlist) {
        super.init(playlist: playlist)
    }
}

extension AnyPlaylist {
    
    var startIndex: Int { return base.startIndex }
    
    var endIndex: Int { return base.endIndex }
}


private class _AnyPlaylistBase<RealmElement: RealmSwift.Object>: PlaylistTypeInternal, CollectionType {
    
    private var objects: AnyRealmCollection<RealmElement> { fatalError() }
    
    private var changes: Observable<CollectionChange> { fatalError() }
    
    private var requestState: Observable<RequestState> { fatalError() }
    
    private var _requestState: Variable<RequestState> { fatalError() }
    
    private var needRefresh: Bool { fatalError() }
    
    var hasNoPaginatedContents: Bool { fatalError() }
    
    subscript (index: Int) -> Track { fatalError() }
    
    
    private func request(refreshing refreshing: Bool) { fatalError() }
    
    private func _any() -> PlaylistType { fatalError() }
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
    
    private override var requestState: Observable<RequestState> { return (base as! Fetchable).requestState }
    
    private override var _requestState: Variable<RequestState> { return (base as! FetchableInternal)._requestState }
    
    private override var needRefresh: Bool { return (base as! FetchableInternal).needRefresh }

    private override var hasNoPaginatedContents: Bool { return (base as! FetchableInternal).hasNoPaginatedContents }
    
    private override func request(refreshing refreshing: Bool) {
        (base as! FetchableInternal).request(refreshing: refreshing)
    }
    
    private override func _any() -> PlaylistType { return base._any() }
}
