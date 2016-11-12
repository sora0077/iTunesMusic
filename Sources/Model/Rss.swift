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
import ErrorEventHandler


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

    public final class Rss: Fetchable, ObservableList, _ObservableList {

        fileprivate var fetched: Int = 0

        fileprivate let id: Int
        fileprivate let url: URL
        public let name: String

        fileprivate var caches: Results<_RssCache>!
        private var token: NotificationToken!
        private var objectsToken: NotificationToken!

        fileprivate var trackIds: [Int] = []

        fileprivate var tracks: AnyRealmCollection<_Track>!

        fileprivate let isFiltered: Bool

        public convenience init(genre: Genre) {
            self.init(genreId: genre.id, rssURL: genre.rssUrls.topSongs, genreName: genre.name, isFiltered: false, filter: { $0 })
        }

        private init<C: RealmCollection>(
            genreId: Int,
            rssURL: URL,
            genreName: String,
            isFiltered: Bool,
            filter: @escaping (List<_Track>) -> C
            ) where C.Element == _Track {

            id = genreId
            url = rssURL
            name = genreName
            self.isFiltered = isFiltered

            let realm = iTunesRealm()
            let feed = getOrCreateCache(genreId: id, realm: realm)
            fetched = feed.fetched
            trackIds = feed.ids

            caches = realm.objects(_RssCache.self).filter("_genreId = \(id)")
            tracks = AnyRealmCollection(filter(caches[0].tracks))
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_RssCache>) {
                    self.caches = results
                    self.tracks = AnyRealmCollection(filter(results[0].tracks))
                    self.objectsToken = self.tracks.addNotificationBlock { [weak self] changes in
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

        public func filter(_ keyword: String) -> Rss {
            let rss = Rss(genreId: id, rssURL: url, genreName: name, isFiltered: true,
                          filter: {
                            $0.filter("_trackName contains '\(keyword)' OR _collection._collectionName contains '\(keyword)'")
                          })
            rss.fetched = fetched
            rss.trackIds = trackIds
            return rss
        }
    }
}


extension Model.Rss: Playlist {

    public var allTrackCount: Int { return isFiltered ? tracks.count : caches[0].ids.count }

    public var trackCount: Int { return tracks.count }

    public var isTrackEmpty: Bool { return tracks.isEmpty }

    public func track(at index: Int) -> Track {
        return tracks[index]
    }
}


extension Model.Rss: _Fetchable {
    
    private static let limit = 200

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 12.hours }

    func request(refreshing: Bool, force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (RequestState) -> Void) {

        if fetched == Model.Rss.limit {
            completion(.done)
            return
        }

        if force || trackIds.isEmpty || (refreshing && _needRefresh) {
            fetchFeed(ifError: errorType, level: level, completion: completion)
            return
        }

        let ids = trackIds[safe: fetched..<(fetched+perItems)]
        if ids.isEmpty {
            completion(.done)
            return
        }
        Session.shared.send(LookupWithIds<LookupResponse>(ids: Array(ids)), callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                completion(requestState)
            }

            switch result {
            case .success(let response):
                let realm = iTunesRealm()
                let cache = getOrCreateCache(genreId: self.id, realm: realm)
                try! realm.write {
                    self.save(response.objects, to: realm)

                    if refreshing {
                        cache.tracks.removeAll()
                        cache.fetched = 0
                        cache.refreshAt = Date()
                    }
                    cache.updateAt = Date()
                    cache.tracks.append(objectsIn: response.objects.reduce([]) { tracks, obj in
                        var tracks = tracks
                        if case .track(let track) = obj {
                            tracks.append(track)
                        }
                        return tracks
                    })
                    cache.fetched += perItems

                    realm.add(cache, update: true)
                    self.fetched = cache.fetched
                }
                requestState = cache.done ? .done : .none
            case .failure(let error):
                print(error)
                requestState = .error(error)
            }
        }
    }

    private func save(_ objects: [LookupResponse.Wrapper], to realm: Realm) {
        objects.forEach {
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
    }

    private func fetchFeed(ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (RequestState) -> Void) {
        Session.shared.send(GetRss<_RssCache>(url: url, limit: Model.Rss.limit), callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let response):
                self.trackIds = response.ids
                self.fetched = response.fetched
                self._requestState.value = .none
                let realm = iTunesRealm()
                try! realm.write {
                    let cache = getOrCreateCache(genreId: self.id, realm: realm)
                    //NOTE: データ取得を挟むため、空のリスト表示から取得までラグがあるため、ここではリストを空にしない
                    //      `cache.tracks.removeAll()`
                    cache.fetched = 0
                    cache.refreshAt = Date()
                }
                DispatchQueue.main.async {
                    self.request(refreshing: true, force: false, ifError: errorType, level: level, completion: completion)
                }
            case .failure(let error):
                print(error)
                completion(.error(error))
            }
        }
    }
}

extension Model.Rss: Swift.Collection {

    public var count: Int { return tracks.count }

    public var isEmpty: Bool { return tracks.isEmpty }

    public var startIndex: Int { return tracks.startIndex }

    public var endIndex: Int { return tracks.endIndex }

    public subscript (index: Int) -> Track { return track(at: index) }

    public func index(after i: Int) -> Int {
        return tracks.index(after: i)
    }
}
