//
//  Genres.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/20.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import APIKit
import Timepiece


private var __requestState = Variable<RequestState>(.none)

private func getOrCreateCache(key: String, realm: Realm) -> _GenresCache {
    if let cache = realm.object(ofType: _GenresCache.self, forPrimaryKey: key) {
        return cache
    } else {
        let cache = _GenresCache()
        cache.key = key
        // swiftlint:disable force_try
        try! realm.write {
            realm.add(cache)
        }
        return cache
    }
}

extension Model {

    public final class Genres: Fetchable, FetchableInternal {

        // swiftlint:disable nesting
        private enum InitialDefaultGenre: Int {

            case top = 34

            case jpop = 27
            case anime = 29

            case electronic = 7

            case disney = 50000063

            case sountTrack = 16
            case jazz = 11

            static var cases: [InitialDefaultGenre] {
                return [
                    .top, .jpop, .anime, .electronic, .disney, .sountTrack, .jazz
                ]
            }
        }

        public var isEmpty: Bool { return caches.isEmpty || cache.list.isEmpty }

        private let _changes = PublishSubject<CollectionChange>()
        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)

        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
        var _requestState: Variable<RequestState> { return __requestState }

        var needRefresh: Bool { return Date() - getOrCreateCache(key: "default", realm: iTunesRealm()).refreshAt > 30.days }

        private var token: NotificationToken?
        private var objectsToken: NotificationToken?
        private let caches: Results<_GenresCache>
        private var cache: _GenresCache {
            return caches[0]
        }

        public init() {

            let realm = iTunesRealm()
            _ = getOrCreateCache(key: "default", realm: realm)
            caches = realm.allObjects(ofType: _GenresCache.self).filter(using: "key == %@", "default").sorted(onProperty: "createAt", ascending: false)
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(_ results: Results<_GenresCache>) {
                    self.objectsToken = results[0].list.addNotificationBlock { [weak self] changes in
                        self?._changes.onNext(CollectionChange(changes))
                    }
                }

                switch changes {
                case .Initial(let results):
                    updateObserver(results)
                case .Update(let results, deletions: _, insertions: let insertions, modifications: _):
                    if !insertions.isEmpty {
                        updateObserver(results)
                    }
                case .Error(let error):
                    fatalError("\(error)")
                }
            }
        }
    }
}

extension Model.Genres {

    func request(refreshing: Bool, force: Bool) {

        if !refreshing && !caches[0].list.isEmpty {
            _requestState.value = .done
            return
        }

        var listGenres = ListGenres<_Genre>()
        listGenres.country = "jp"
        Session.sharedSession.sendRequest(listGenres, callbackQueue: callbackQueue) { result in
            defer {
                tick()
            }
            switch result {
            case .success(let cache):
                let realm = iTunesRealm()
                try! realm.write {
                    realm.add(cache, update: true)

                    let cache = getOrCreateCache(key: "default", realm: realm)
                    if refreshing {
                        cache.list.removeAllObjects()
                        cache.refreshAt = Date()
                    }

                    for genre in InitialDefaultGenre.cases {
                        cache.list.append(realm.object(ofType: _Genre.self, forPrimaryKey: genre.rawValue)!)
                    }
                    realm.add(cache)
                }
                __requestState.value = .done
            case .failure(let error):
                print(error)
                __requestState.value = .error
            }
        }
    }
}

extension Model.Genres: Swift.Collection {

    public var startIndex: Int { return isEmpty ? 0 : cache.list.startIndex }

    public var endIndex: Int { return isEmpty ? 0 : cache.list.endIndex }

    public subscript (index: Int) -> Genre {
        return cache.list[index]
    }

    public func index(after i: Int) -> Int {
        return cache.list.index(after: i)
    }
}
