//
//  Album.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/02.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Timepiece
import APIKit
import ErrorEventHandler

private func getOrCreateCache(collectionId: Int, realm: Realm) -> _AlbumCache {
    if let cache = realm.object(ofType: _AlbumCache.self, forPrimaryKey: collectionId) {
        return cache
    }
    let cache = _AlbumCache()
    cache.collectionId = collectionId
    cache.collection = realm.object(ofType: _Collection.self, forPrimaryKey: collectionId)!
    // swiftlint:disable:next force_try
    try! realm.write {
        realm.add(cache)
    }
    return cache
}

extension Model {

    public final class Album: Fetchable, ObservableList, _ObservableList {

        private var objectsToken: NotificationToken?
        private var token: NotificationToken?

        fileprivate let collectionId: Int

        fileprivate let caches: Results<_AlbumCache>
        fileprivate var tracks: Results<_Track>

        public convenience init(collection: Collection) {
            self.init(collectionId: collection.id)
        }

        public init(collectionId: Int) {
            self.collectionId = collectionId
            let realm = iTunesRealm()
            let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
            caches = realm.objects(_AlbumCache.self).filter("collectionId = \(collectionId)")
            tracks = caches[0].collection.sortedTracks
            token = caches.observe { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_AlbumCache>) {
                    let tracks = results[0].collection.sortedTracks
                    self.objectsToken = tracks.observe { [weak self] changes in
                        self?._changes.onNext(CollectionChange(changes))
                    }
                    self.tracks = tracks
                }

                switch changes {
                case .initial(let results):
                    updateObserver(with: results)
                case .update(let results, deletions: _, insertions: let insertions, modifications: _):
                    if !insertions.isEmpty {
                        updateObserver(with: results)
                    }
                case .error(let error):
                    fatalError("\(error)")
                }
            }
        }
    }
}

extension Model.Album: Playlist {

    public var name: String { return collection.name }

    public var allTrackCount: Int { return collection.trackCount }

    public var trackCount: Int { return tracks.count }

    public var isTrackEmpty: Bool { return tracks.isEmpty }

    public func track(at index: Int) -> Track { return tracks[index] }
}

extension Model.Album {

    public var collection: Collection {
        return caches[0].collection
    }
}

extension Model.Album: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 60.minutes }
}

extension Model.Album: _FetchableSimple {

    typealias Request = LookupWithIds<LookupResponse>

    private var _collection: _Collection { return caches[0].collection }

    func makeRequest(refreshing: Bool) -> Request? {
        if !refreshing && _collection._trackCount == _collection.sortedTracks.count {
            return nil
        }
        return LookupWithIds(id: collectionId)
    }

    func doResponse(_ response: Request.Response, request: Request, refreshing: Bool) -> RequestState {
        let realm = iTunesRealm()
        // swiftlint:disable:next force_try
        try! realm.write {
            var collectionNames: [Int: String] = [:]
            var collectionCensoredNames: [Int: String] = [:]
            response.objects.reversed().forEach {
                switch $0 {
                case .track(let obj):
                    if let c = obj._collection {
                        collectionNames[c._collectionId] = c._collectionName
                        collectionCensoredNames[c._collectionId] = c._collectionCensoredName
                    }
                    realm.add(obj, update: true)
                case .collection(let obj):
                    if let name = collectionNames[obj._collectionId] {
                        obj._collectionName = name
                    }
                    if let name = collectionCensoredNames[obj._collectionId] {
                        obj._collectionCensoredName = name
                    }
                    realm.add(obj, update: true)
                case .artist(let obj):
                    realm.add(obj, update: true)
                case .unknown:()
                }
            }
            let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
            cache.updateAt = Date()
            if refreshing {
                cache.refreshAt = Date()
            }
        }
        return .done
    }
}

extension Model.Album: Swift.Collection {

    public var count: Int { return trackCount }

    public var isEmpty: Bool { return isTrackEmpty }

    public var startIndex: Int { return tracks.startIndex }

    public var endIndex: Int { return tracks.endIndex }

    public subscript (index: Int) -> Track { return track(at: index) }

    public func index(after i: Int) -> Int {
        return tracks.index(after: i)
    }
}
