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


private func getOrCreateCache(realm: Realm) -> _MyPlaylistCache {
    if let cache = realm.objects(_MyPlaylistCache.self).first {
        return cache
    }
    let cache = _MyPlaylistCache()
    // swiftlint:disable force_try
    try! realm.write {
        let playlist = _MyPlaylist()
        playlist.title = "お気に入り"
        cache.playlists.append(playlist)
        realm.add(cache)
    }
    return cache
}

extension Model {

    public final class MyPlaylists: ObservableList, _ObservableList {

        fileprivate let cache: _MyPlaylistCache
        private var token: NotificationToken?

        public init() {

            let realm = iTunesRealm()
            cache = getOrCreateCache(realm: realm)
            token = cache.playlists.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                self._changes.onNext(CollectionChange(changes))
            }
        }
    }
}

extension Model.MyPlaylists {

    public func insert(playlist: Model.MyPlaylist, at index: Int) {
        let realm = iTunesRealm()
        try! realm.write {
            cache.playlists.insert(playlist.playlist, at: index)
        }
    }

    public func append(playlist: Model.MyPlaylist) {
        let realm = iTunesRealm()
        try! realm.write {
            cache.playlists.append(playlist.playlist)
        }
    }

    public func remove(at index: Int) {
        let realm = iTunesRealm()
        try! realm.write {
            cache.playlists.remove(objectAtIndex: index)
        }
    }

    public func move(from src: Int, to dst: Int) {
        let realm = iTunesRealm()
        try! realm.write {
            cache.playlists.move(from: src, to: dst)
        }
    }
}

extension Model.MyPlaylists: Swift.Collection {

    public var startIndex: Int { return cache.playlists.startIndex }

    public var endIndex: Int { return cache.playlists.endIndex }

    public subscript (index: Int) -> iTunesMusic.MyPlaylist {
        return cache.playlists[index]
    }

    public func index(after i: Int) -> Int {
        return cache.playlists.index(after: i)
    }
}


//MARK: - Model.MyPlaylist

extension Model {

    public final class MyPlaylist: ObservableList, _ObservableList {

        fileprivate var token: NotificationToken?

        fileprivate let playlist: _MyPlaylist

        public init(playlist: iTunesMusic.MyPlaylist) {
            let playlist = playlist.impl
            self.playlist = playlist

            token = playlist.tracks.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                self._changes.onNext(CollectionChange(changes))
            }
        }
    }
}


extension Model.MyPlaylist: Playlist {

    public var name: String { return playlist.title }

    public var allTrackCount: Int { return trackCount }

    public var trackCount: Int { return playlist.tracks.count }

    public var isTrackEmpty: Bool { return playlist.tracks.isEmpty }

    public func track(at index: Int) -> Track { return playlist.tracks[index] }
}


extension Model.MyPlaylist {

    public func insert(track: Track, at index: Int) {
        let realm = iTunesRealm()
        // swiftlint:disable force_try
        try! realm.write {
            playlist.tracks.insert(track.impl, at: index)
        }
    }

    public func append(track: Track) {
        let realm = iTunesRealm()
        // swiftlint:disable force_try
        try! realm.write {
            playlist.tracks.append(track.impl)
        }
    }

    public func remove(at index: Int) {
        let realm = iTunesRealm()
        // swiftlint:disable force_try
        try! realm.write {
            playlist.tracks.remove(objectAtIndex: index)
        }
    }

    public func move(from src: Int, to dst: Int) {
        let realm = iTunesRealm()
        // swiftlint:disable force_try
        try! realm.write {
            playlist.tracks.move(from: src, to: dst)
        }
    }
}

extension Model.MyPlaylist: Swift.Collection {

    public var count: Int { return trackCount }

    public var isEmpty: Bool { return isTrackEmpty }

    public var startIndex: Int { return playlist.tracks.startIndex }

    public var endIndex: Int { return playlist.tracks.endIndex }

    public subscript (index: Int) -> Track { return track(at: index) }

    public func index(after i: Int) -> Int {
        return playlist.tracks.index(after: i)
    }
}
