//
//  Reviews.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/28.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import RealmSwift
import RxSwift
import Timepiece
import ErrorEventHandler

private func getOrCreateCache(collectionId: Int, realm: Realm) -> _ReviewCache {
    if let cache = realm.object(ofType: _ReviewCache.self, forPrimaryKey: collectionId) {
        return cache
    }
    let cache = _ReviewCache()
    cache.collectionId = collectionId
    // swiftlint:disable:next force_try
    try! realm.write {
        realm.add(cache)
    }
    return cache
}

extension Model {

    public final class Reviews: Fetchable, ObservableList, _ObservableList {

        fileprivate let collectionId: Int

        fileprivate let caches: Results<_ReviewCache>

        private var token: NotificationToken!
        private var objectsToken: NotificationToken!

        public init(collection: iTunesMusic.Collection) {
            collectionId = collection.id

            let realm = iTunesRealm()
            _ = getOrCreateCache(collectionId: collectionId, realm: realm)
            caches = realm.objects(_ReviewCache.self).filter("collectionId = \(collectionId)")
            token = caches.observe { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_ReviewCache>) {
                    self.objectsToken = results[0].objects.observe { [weak self] changes in
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

extension Model.Reviews: _Fetchable {

    var _refreshAt: Date { return caches[0].refreshAt }

    var _refreshDuration: Duration { return 6.hours }
}

extension Model.Reviews: _FetchableSimple {

    typealias Request = ListReviews<_Review>

    func makeRequest(refreshing: Bool) -> Request? {
        let cache = caches[0]
        if !refreshing && cache.fetched {
            return nil
        }
        return ListReviews(id: collectionId, page: refreshing ? 1 : UInt(cache.page))
    }

    func doResponse(_ response: Request.Response, request: Request, refreshing: Bool) -> RequestState {
        let realm = iTunesRealm()
        // swiftlint:disable:next force_try
        try! realm.write {
            realm.add(response, update: true)

            let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
            if refreshing {
                cache.refreshAt = Date()
                cache.page = 1
                cache.fetched = false
                cache.objects.removeAll()
            }
            cache.updateAt = Date()
            cache.fetched = response.isEmpty
            cache.page += 1
            cache.objects.append(objectsIn: response)
        }
        return response.isEmpty ? .done : .none
    }
}

extension Model.Reviews: Swift.Collection {

    private var objects: List<_Review> { return caches[0].objects }

    public var startIndex: Int { return objects.startIndex }

    public var endIndex: Int { return objects.endIndex }

    public subscript (index: Int) -> Review { return objects[index] }

    public func index(after i: Int) -> Int {
        return objects.index(after: i)
    }
}
