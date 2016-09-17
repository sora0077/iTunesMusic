//
//  Search.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import APIKit
import Timepiece
import ErrorEventHandler


fileprivate func getOrCreateCache(term: String, realm: Realm) -> _SearchCache {
    if let cache = realm.object(ofType: _SearchCache.self, forPrimaryKey: term) {
        return cache
    } else {
        let cache = _SearchCache()
        // swiftlint:disable force_try
        try! realm.write {
            cache.term = term
            realm.add(cache)
        }
        return cache
    }
}

extension Model {

    public final class Search: Fetchable, ObservableList, _ObservableList {

        // swiftlint:disable nesting
        public final class Trends: Fetchable, ObservableList, _ObservableList {
            public var name: String {
                return cache.name
            }
            fileprivate var results: [String] = []

            fileprivate let cache: _SearchTrendsCache

            fileprivate init() {
                let realm = iTunesRealm()
                self.cache = realm.objects(_SearchTrendsCache.self).first ?? _SearchTrendsCache()
                try! realm.write {
                    realm.add(self.cache, update: true)
                }
                DispatchQueue.main.async {
                    self.results = self.cache.trendings
                    self._changes.onNext(.initial)
                }
            }
        }

        public let trends = Trends()

        public var name: String { return term }

        fileprivate let term: String
        fileprivate let caches: Results<_SearchCache>
        fileprivate var tracks: Results<_Media>
        private var token: NotificationToken!
        private var objectsToken: NotificationToken?
        private var tracksToken: NotificationToken?


        public private(set) lazy var tracksChanges: Observable<CollectionChange> = asObservable(self._tracksChanges)
        private let _tracksChanges = PublishSubject<CollectionChange>()

        public init(term: String) {
            self.term = term

            let realm = iTunesRealm()
            _ = getOrCreateCache(term: term, realm: realm)
            caches = realm.objects(_SearchCache.self).filter("term = %@", term)
            tracks = caches[0].objects.filter("track != nil")
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_SearchCache>) {
                    self.tracks = results[0].objects.filter("track != nil")
                    self.tracksToken = self.tracks.addNotificationBlock { [weak self] changes in
                        self?._tracksChanges.onNext(CollectionChange(changes))
                    }
                    self.objectsToken = results[0].objects.addNotificationBlock { [weak self] changes in
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


extension Model.Search: PlaylistType {

    public var trackCount: Int { return tracks.count }

    public var isTrackEmpty: Bool { return tracks.isEmpty }

    public func track(at index: Int) -> Track { return tracks[index].track! }
}


extension Model.Search: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 60.minutes }

    func request(refreshing: Bool, force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (RequestState) -> Void) {
        if term.isEmpty { completion(.none); return }

        _refreshing.value = refreshing

        let search = SearchWithKeyword<SearchResponse>(term: term, offset: refreshing ? 0 : caches[0].offset)
        Session.sharedSession.send(search, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                completion(requestState)
            }
            switch result {
            case .success(let response):
                let realm = iTunesRealm()
                let cache = getOrCreateCache(term: self.term, realm: realm)
                // swiftlint:disable force_try
                try! realm.write {
                    var medias: [_Media] = []
                    response.objects.reversed().forEach {
                        switch $0 {
                        case .track(let obj):
                            medias.append(_Media.track(track: obj))
                            realm.add(obj, update: true)
                        case .collection(let obj):
                            medias.append(_Media.collection(collection: obj))
                            realm.add(obj, update: true)
                        case .artist(let obj):
                            medias.append(_Media.artist(artist: obj))
                            realm.add(obj, update: true)
                        }
                    }
                    if refreshing {
                        cache.objects.removeAll()
                        cache.refreshAt = Date()
                        cache.offset = 0
                    }
                    cache.objects.append(objectsIn: medias.reversed())
                    cache.updateAt = Date()
                    cache.offset += response.objects.count
                }
                print("search result cached")
                requestState = response.objects.count != search.limit ? .done : .none
            case .failure(let error):
                print(error)
                requestState = .error(error)
            }
        }
    }
}

extension Model.Search: Swift.Collection {

    public enum Result {
        case track(Track)
        case collection(Collection)
        case artist(Artist)

        fileprivate init(type: _Media.MediaType) {
            switch type {
            case let .track(obj):
                self = .track(obj)
            case let .collection(obj):
                self = .collection(obj)
            case let .artist(obj):
                self = .artist(obj)
            }
        }
    }

    fileprivate var results: List<_Media> { return caches[0].objects }

    public var count: Int { return results.count }

    public var isEmpty: Bool { return results.isEmpty }

    public var startIndex: Int { return results.startIndex }

    public var endIndex: Int { return results.endIndex }

    public subscript (index: Int) -> Result {
        return Result(type: results[index].type)
    }

    public func index(after i: Int) -> Int {
        return results.index(after: i)
    }
}

//MARK: - Search.Trends
extension Model.Search.Trends: _Fetchable {

    var _refreshAt: Date { return cache.refreshAt }

    var _refreshDuration: Duration { return 60.minutes }

    func request(refreshing: Bool, force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (RequestState) -> Void) {

        let trends = SearchHintTrends()
        Session.sharedSession.send(trends, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                completion(requestState)
            }
            switch result {
            case .success(let response):
                let realm = iTunesRealm()
                try! realm.write {
                    let cache = realm.objects(_SearchTrendsCache.self).first ?? _SearchTrendsCache()
                    cache.name = response.name
                    cache.trendings = response.trends
                    cache.updateAt = Date()
                    if refreshing {
                        cache.refreshAt = Date()
                    }
                    realm.add(cache, update: true)
                }
                let indices = response.trends.enumerated().map { $0.offset }
                let changes: CollectionChange
                if self.results.count == indices.count {
                    changes = .update(deletions: [], insertions: [], modifications: indices)
                } else {
                    changes = .update(deletions: [], insertions: indices, modifications: [])
                }
                self.results = response.trends
                DispatchQueue.main.async {
                    self._changes.onNext(changes)
                }
                requestState = .done
            case .failure(let error):
                print(error)
                requestState = .error(error)
            }
        }
    }
}

extension Model.Search.Trends: Swift.Collection {

    public var count: Int { return results.count }

    public var isEmpty: Bool { return results.isEmpty }

    public var startIndex: Int { return results.startIndex }

    public var endIndex: Int { return results.endIndex }

    public subscript (index: Int) -> String { return results[index] }

    public func index(after i: Int) -> Int { return results.index(after: i) }
}
