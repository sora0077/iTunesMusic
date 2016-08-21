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


fileprivate func getOrCreateCache(artistId: Int, realm: Realm) -> _ArtistCache {
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

        fileprivate var objectsToken: NotificationToken?
        fileprivate var token: NotificationToken?

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
            caches = realm.allObjects(ofType: _ArtistCache.self).filter(using: "artistId = \(artistId)")
            collections = caches[0].artist._collections.sorted(onProperty: "_collectionId", ascending: false)
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_ArtistCache>) {
                    self.collections = results[0].artist._collections.sorted(onProperty: "_collectionId", ascending: false)
                    self.objectsToken = self.collections.addNotificationBlock { [weak self] changes in
                        self?._changes.onNext(CollectionChange(changes))
                    }
                }

                switch changes {
                case .Initial(let results):
                    updateObserver(with: results)
                case .Update(let results, deletions: _, insertions: let insertions, modifications: _):
                    if !insertions.isEmpty {
                        updateObserver(with: results)
                    }
                case .Error(let error):
                    fatalError("\(error)")
                }
            }
        }
    }
}

extension Model.Artist: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 60.minutes }

    func request(refreshing: Bool, force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (RequestState) -> Void) {

        let artistId = self.artistId
        let cache = caches[0]
        if !refreshing && cache.fetched {
            completion(.done)
            return
        }

        let session = Session.sharedSession

        let lookup = LookupWithIds<LookupResponse>(id: artistId)
        session.sendRequest(lookup, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                completion(requestState)
            }
            switch result {
            case .success(let response):
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
                        }
                    }

                    let cache = getOrCreateCache(artistId: artistId, realm: realm)
                    if refreshing {
                        cache.refreshAt = Date()
                    }
                    cache.updateAt = Date()
                    cache.fetched = true
                }
                requestState = .done
            case .failure(let error):
                print(error)
                requestState = .error
            }
        }
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
