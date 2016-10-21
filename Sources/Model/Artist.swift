//
//  Artist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/04.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import APIKit
import Timepiece
import Himotoki
import ErrorEventHandler


private func getOrCreateCache(artistId: Int, realm: Realm) -> _ArtistCache {
    if let cache = realm.object(ofType: _ArtistCache.self, forPrimaryKey: artistId) {
        return cache
    }
    let cache = _ArtistCache()
    cache.artistId = artistId
    cache.artist = realm.object(ofType: _Artist.self, forPrimaryKey: artistId)!
    // swiftlint:disable force_try
    try! realm.write {
        realm.add(cache)
    }
    return cache
}

extension Model {

    public final class Artist: Fetchable, ObservableList, _ObservableList {

        private var objectsToken: NotificationToken?
        private var token: NotificationToken?

        fileprivate let artistId: Int

        fileprivate let caches: Results<_ArtistCache>
        fileprivate var collections: Results<_Collection>

        public convenience init(artist: iTunesMusic.Artist) {
            self.init(artistId: artist.id)
        }

        public init(artistId: Int) {
            self.artistId = artistId

            let realm = iTunesRealm()
            _ = getOrCreateCache(artistId: artistId, realm: realm)
            caches = realm.objects(_ArtistCache.self).filter("artistId = \(artistId)")
            collections = caches[0].artist.sortedCollections
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_ArtistCache>) {
                    self.collections = results[0].artist.sortedCollections
                    self.objectsToken = self.collections.addNotificationBlock { [weak self] changes in
                        self?._changes.onNext(CollectionChange(changes))
                    }
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

extension Model.Artist: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 60.minutes }
}

extension Model.Artist: _FetchableSimple {

    typealias Request = LookupWithIds<LookupResponse>

    func makeRequest(refreshing: Bool) -> Request? {
        if !refreshing && caches[0].fetched {
            return nil
        }
        return LookupWithIds(id: artistId)
    }

    func doResponse(_ response: Request.Response, request: Request, refreshing: Bool) -> RequestState {
        let realm = iTunesRealm()
        // swiftlint:disable force_try
        try! realm.write {
            response.objects.forEach {
                switch $0 {
                case .track(let obj):
                    realm.add(obj, update: true)
                case .collection(let obj):
                    realm.add(obj, update: true)
                case .artist(let obj):
                    realm.add(obj, update: true)
                case .unknown:()
                }
            }

            let cache = getOrCreateCache(artistId: artistId, realm: realm)
            if refreshing {
                cache.refreshAt = Date()
            }
            cache.updateAt = Date()
            cache.fetched = true
        }
        return .done
    }
}

extension Model.Artist: Swift.Collection {

    public var startIndex: Int { return collections.startIndex }

    public var endIndex: Int { return collections.endIndex }

    public subscript (index: Int) -> Collection { return collections[index] }

    public func index(after i: Int) -> Int {
        return collections.index(after: i)
    }
}
