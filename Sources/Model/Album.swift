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


private func getOrCreateCache(collectionId: Int, realm: Realm) -> _AlbumCache {
    if let cache = realm.object(ofType: _AlbumCache.self, forPrimaryKey: collectionId) {
        return cache
    }
    let cache = _AlbumCache()
    cache.collectionId = collectionId
    cache.collection = realm.object(ofType: _Collection.self, forPrimaryKey: collectionId)!
    // swiftlint:disable force_try
    try! realm.write {
        realm.add(cache)
    }
    return cache
}

private let sortConditions = [
    SortDescriptor(property: "_discNumber", ascending: true),
    SortDescriptor(property: "_trackNumber", ascending: true)
]


extension Model {

    public final class Album: Fetchable, ObservableList, _ObservableList {

        private var objectsToken: NotificationToken?
        private var token: NotificationToken?

        private let collectionId: Int

        private let caches: Results<_AlbumCache>
        private var tracks: Results<_Track>

        public convenience init(collection: Collection) {
            self.init(collectionId: collection.id)
        }

        public init(collectionId: Int) {
            self.collectionId = collectionId
            let realm = iTunesRealm()
            let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
            caches = realm.allObjects(ofType: _AlbumCache.self).filter(using: "collectionId = \(collectionId)")
            tracks = caches[0].collection._tracks.sorted(with: sortConditions)
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_AlbumCache>) {
                    let tracks = results[0].collection
                        ._tracks
                        .sorted(with: sortConditions)
                    self.objectsToken = tracks.addNotificationBlock { [weak self] changes in
                        self?._changes.onNext(CollectionChange(changes))
                    }
                    self.tracks = tracks
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


extension Model.Album: PlaylistType {

    public var name: String { return collection.name }

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

    func request(refreshing: Bool, force: Bool, completion: (RequestState) -> Void) {

        let collectionId = self.collectionId
        let cache = caches[0]
        if !refreshing && cache.collection._trackCount == cache.collection._tracks.count {
            completion(.done)
            return
        }

        let session = Session.sharedSession

        let lookup = LookupWithIds<LookupResponse>(id: collectionId)
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
                    response.objects.reversed().forEach {
                        switch $0 {
                        case .track(let obj):
                            realm.add(obj, update: true)
                        case .collection(let obj):
                            realm.add(obj, update: true)
                        case .artist(let obj):
                            realm.add(obj, update: true)
                        }
                    }

                    let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
                    cache.updateAt = Date()
                    if refreshing {
                        cache.refreshAt = Date()
                    }
                }
                requestState = .done
            case .failure(let error):
                print(error)
                requestState = .error
            }
        }
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
