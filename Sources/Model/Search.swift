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

    public final class Search: Fetchable, ObservableList, _ObservableList {

        public var name: String { return term }

        private let term: String
        private let caches: Results<_SearchCache>
        private var token: NotificationToken!
        private var objectsToken: NotificationToken?
        private var tracksToken: NotificationToken?

        private var tracks: Results<_Media>

        public private(set) lazy var tracksChanges: Observable<CollectionChange> = asObservable(self._tracksChanges)
        private let _tracksChanges = PublishSubject<CollectionChange>()

        public init(term: String) {
            self.term = term

            let realm = iTunesRealm()
            _ = getOrCreateCache(term: term, realm: realm)
            caches = realm.allObjects(ofType: _SearchCache.self).filter(using: "term = %@", term)
            tracks = caches[0].objects.filter(using: "track != nil")
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_SearchCache>) {
                    self.tracks = results[0].objects.filter(using: "track != nil")
                    self.tracksToken = self.tracks.addNotificationBlock { [weak self] changes in
                        self?._tracksChanges.onNext(CollectionChange(changes))
                    }
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


extension Model.Search: PlaylistType {

    public var trackCount: Int { return tracks.count }

    public var isTrackEmpty: Bool { return tracks.isEmpty }

    public func track(at index: Int) -> Track { return tracks[index].track! }
}


extension Model.Search: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 60.minutes }

    func request(refreshing: Bool, force: Bool, completion: (RequestState) -> Void) {
        if term.isEmpty { completion(.none); return }

        _refreshing.value = refreshing

        let search = SearchWithKeyword<SearchResponse>(term: term, offset: refreshing ? 0 : caches[0].offset)
        Session.sharedSession.sendRequest(search, callbackQueue: callbackQueue) { [weak self] result in
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
                        cache.objects.removeAllObjects()
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
                requestState = .error
            }
        }
    }
}

extension Model.Search: Swift.Collection {

    public enum Result {
        case track(Track)
        case collection(Collection)
        case artist(Artist)
    }

    private var results: List<_Media> { return caches[0].objects }

    public var count: Int { return results.count }

    public var isEmpty: Bool { return results.isEmpty }

    public var startIndex: Int { return results.startIndex }

    public var endIndex: Int { return results.endIndex }

    public subscript (index: Int) -> Result {
        switch caches[0].objects[index].object {
        case let obj as Track:
            return .track(obj)
        case let obj as Collection:
            return .collection(obj)
        case let obj as Artist:
            return .artist(obj)
        default:
            fatalError()
        }
    }

    public func index(after i: Int) -> Int {
        return results.index(after: i)
    }
}
