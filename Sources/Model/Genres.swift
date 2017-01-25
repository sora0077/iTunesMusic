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
import ErrorEventHandler

private let __requestState = Variable<RequestState>(.none)

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

    public final class Genres: Fetchable, ObservableList, _ObservableList {

        // swiftlint:disable nesting
        fileprivate enum InitialDefaultGenre: Int {

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

            var name: String? {
                if self == .top {
                    return "すべてのジャンル"
                }
                return nil
            }
        }

        public var isEmpty: Bool { return caches.isEmpty || cache.list.isEmpty }

        var _requestState: Variable<RequestState> { return __requestState }

        private var token: NotificationToken?
        private var objectsToken: NotificationToken?
        private let caches: Results<_GenresCache>
        fileprivate var cache: _GenresCache {
            return caches[0]
        }

        public init() {

            let realm = iTunesRealm()
            _ = getOrCreateCache(key: "default", realm: realm)
            caches = realm.objects(_GenresCache.self).filter("key == %@", "default").sorted(byProperty: "createAt", ascending: false)
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(_ results: Results<_GenresCache>) {
                    self.objectsToken = results[0].list.addNotificationBlock { [weak self] changes in
                        self?._changes.onNext(CollectionChange(changes))
                    }
                }

                switch changes {
                case .initial(let results):
                    updateObserver(results)
                case .update(let results, deletions: _, insertions: let insertions, modifications: _):
                    if !insertions.isEmpty {
                        updateObserver(results)
                    }
                case .error(let error):
                    fatalError("\(error)")
                }
            }
        }
    }
}

extension Model.Genres: _Fetchable {

    var _refreshAt: Date { return cache.refreshAt }

    var _refreshDuration: Duration { return 30.days }
}

extension Model.Genres: _FetchableSimple {

    typealias Request = ListGenres<_Genre>

    func makeRequest(refreshing: Bool) -> Request? {
        if !refreshing && !cache.list.isEmpty {
            return nil
        }
        return ListGenres()
    }

    func doResponse(_ response: Request.Response, request: Request, refreshing: Bool) -> RequestState {
        let realm = iTunesRealm()
        try! realm.write {
            realm.add(response, update: true)

            let cache = getOrCreateCache(key: "default", realm: realm)
            cache.updateAt = Date()
            if refreshing {
                cache.list.removeAll()
                cache.refreshAt = Date()
            }

            for genreType in InitialDefaultGenre.cases {
                let genre = realm.object(ofType: _Genre.self, forPrimaryKey: genreType.rawValue)!
                if let name = genreType.name {
                    genre.name = name
                }
                cache.list.append(genre)
            }
            realm.add(cache)
        }
        return .done
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
