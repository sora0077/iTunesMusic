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


private func getOrCreateCache(term: String, realm: Realm) -> _SearchCache {
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

    public final class Search: PlaylistType, Fetchable, _ObservableList {

        var name: String { return term }

        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)

        private let _refreshing = Variable<Bool>(false)

        private let term: String
        private let caches: Results<_SearchCache>
        private var token: NotificationToken!
        private var objectsToken: NotificationToken?

        public init(term: String) {
            self.term = term

            let realm = iTunesRealm()
            _ = getOrCreateCache(term: term, realm: realm)
            caches = realm.allObjects(ofType: _SearchCache.self).filter(using: "term = %@", term)
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_SearchCache>) {
                    self.objectsToken = results[0].objects.addNotificationBlock { [weak self] changes in
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


extension Model.Search: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 60.minutes }

    func request(refreshing: Bool, force: Bool) {
        if term.isEmpty { return }

        _refreshing.value = refreshing

        let search = SearchWithKeyword<SearchResponse>(term: term, offset: refreshing ? 0 : caches[0].offset)
        Session.sharedSession.sendRequest(search, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            defer {
                self._refreshing.value = false
                tick()
            }
            switch result {
            case .success(let response):
                let realm = iTunesRealm()
                let cache = getOrCreateCache(term: self.term, realm: realm)
                // swiftlint:disable force_try
                try! realm.write {
                    var tracks: [_Track] = []
                    response.objects.reversed().forEach {
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
                    if refreshing {
                        cache.objects.removeAllObjects()
                        cache.refreshAt = Date()
                        cache.offset = 0
                    }
                    cache.objects.append(objectsIn: tracks.reversed())
                    cache.updateAt = Date()
                    cache.offset += response.objects.count
                }
                print("search result cached")
                self._requestState.value = response.objects.count != search.limit ? .done : .none
                print(self._requestState.value)
            case .failure(let error):
                print(error)
                self._requestState.value = .error
            }
        }
    }
}

extension Model.Search: Swift.Collection {

    var tracks: List<_Track> {
        return caches[0].objects
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
