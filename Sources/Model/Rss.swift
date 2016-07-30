//
//  Rss.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import RxSwift
import RealmSwift
import Timepiece


private func getOrCreateCache(genreId: Int, realm: Realm) -> _RssCache {
    if let cache = realm.object(ofType: _RssCache.self, forPrimaryKey: genreId) {
        return cache
    } else {
        let cache = _RssCache()
        // swiftlint:disable force_try
        try! realm.write {
            cache._genreId = genreId
            realm.add(cache)
        }
        return cache
    }
}

private let perItems = 50

extension Model {

    public final class Rss: PlaylistType, Fetchable, _ObservableList {

        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)

        private var fetched: Int = 0

        private let id: Int
        private let url: URL

        private let caches: Results<_RssCache>
        private var token: NotificationToken!
        private var objectsToken: NotificationToken!

        private var trackIds: [Int] = []

        public init(genre: Genre) {
            id = genre.id
            url = genre.rssUrls.topSongs

            let realm = iTunesRealm()
            let feed = getOrCreateCache(genreId: id, realm: realm)
            fetched = feed.fetched
            trackIds = feed.ids

            caches = realm.allObjects(ofType: _RssCache.self).filter(using: "_genreId = \(id)")
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_RssCache>) {
                    self.objectsToken = results[0].tracks.addNotificationBlock { [weak self] changes in
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


extension Model.Rss: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 3.hours }

    func request(refreshing: Bool, force: Bool) {
        if trackIds.isEmpty || (refreshing && _needRefresh) {
            fetchFeed()
            return
        }

        let session = Session.sharedSession

        let ids = trackIds[safe: fetched..<(fetched+perItems)]
        if ids.isEmpty {
            _requestState.value = .done
            return
        }
        let lookup = LookupWithIds<LookupResponse>(ids: Array(ids))
        session.sendRequest(lookup, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                self._requestState.value = requestState
                tick()
            }

            switch result {
            case .success(let response):
                let realm = iTunesRealm()
                let cache = getOrCreateCache(genreId: self.id, realm: realm)
                try! realm.write {
                    var tracks: [_Track] = []
                    response.objects.forEach {
                        switch $0 {
                        case .track(let obj):
                            tracks.append(obj)
                            realm.add(obj, update: true)
                        case .collection(let obj):
                            realm.add(obj, update: true)
                        case .artist(let obj):
                            realm.add(obj, update: true)
                        }
                    }

                    cache.tracks.append(objectsIn: tracks)
                    cache.fetched += perItems
                    realm.add(cache, update: true)
                    self.fetched = cache.fetched
                }
                requestState = cache.done ? .done : .none
            case .failure(let error):
                print(error)
                requestState = .error
            }
        }
    }

    private func fetchFeed() {

        let id = self.id

        let session = Session.sharedSession

        session.sendRequest(GetRss<_RssCache>(url: url, limit: 200), callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                self._requestState.value = requestState
                tick()
            }

            switch result {
            case .success(let response):
                let realm = iTunesRealm()
                try! realm.write {
                    let genre = realm.object(ofType: _Genre.self, forPrimaryKey: id)
                    response._genreId = genre?.id ?? 0
                    response.tracks.removeAllObjects()
                    response.refreshAt = Date()
                    realm.add(response, update: true)
                }
                self.trackIds = response.ids
                self.fetched = response.fetched
                self.request(refreshing: false, force: false)
                requestState = .none
            case .failure(let error):
                print(error)
                requestState = .error
            }
        }
    }
}

extension Model.Rss: Swift.Collection {

    var tracks: List<_Track> {
        return caches[0].tracks
    }

    public var count: Int { return tracks.count }

    public var isEmpty: Bool { return tracks.isEmpty }

    public var startIndex: Int { return tracks.startIndex }

    public var endIndex: Int { return tracks.endIndex }

    public subscript (index: Int) -> Track { return tracks[index] }

    public func index(after i: Int) -> Int {
        return tracks.index(after: i)
    }
}
