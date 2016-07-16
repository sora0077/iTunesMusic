//
//  MyPlaylist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/16.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift


private func getOrCreateCache(realm realm: Realm) -> _MyPlaylistCache {
    if let cache = realm.objects(_MyPlaylistCache).first {
        return cache
    }
    let cache = _MyPlaylistCache()
    try! realm.write {
        let playlist = _MyPlaylist()
        playlist.title = "お気に入り"
        cache.playlists.append(playlist)
        realm.add(cache)
    }
    return cache
}

extension Model {
    
    public final class MyPlaylists {
        
        private let _changes = PublishSubject<CollectionChange>()
        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        
        private let cache: _MyPlaylistCache
        private var token: NotificationToken?
        
        public init() {
            
            let realm = try! iTunesRealm()
            cache = getOrCreateCache(realm: realm)
            token = cache.playlists.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }
                
                self._changes.onNext(CollectionChange(changes))
            }
        }
    }
}

extension Model.MyPlaylists: CollectionType {
    
    public var startIndex: Int { return cache.playlists.startIndex }
    
    public var endIndex: Int { return cache.playlists.endIndex }
    
    public subscript (index: Int) -> iTunesMusic.MyPlaylist {
        return cache.playlists[index]
    }
}


//MARK: - Model.MyPlaylist

extension Model {
    
    public final class MyPlaylist: PlaylistType {
        
        private let _changes = PublishSubject<CollectionChange>()
        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        
        private var token: NotificationToken?
        
        private let playlist: _MyPlaylist
        
        public init(playlist: iTunesMusic.MyPlaylist) {
            let playlist = playlist as! _MyPlaylist
            self.playlist = playlist
            
            token = playlist.tracks.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }
                
                self._changes.onNext(CollectionChange(changes))
            }
        }
    }
}

extension Model.MyPlaylist {
    
    public func add(track track: Track) {
        let realm = try! iTunesRealm()
        try! realm.write {
            playlist.tracks.append(track as! _Track)
        }
    }
}

extension Model.MyPlaylist: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_Track> { return AnyRealmCollection(playlist.tracks) }
}


extension Model.MyPlaylist: CollectionType {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index] }
}
