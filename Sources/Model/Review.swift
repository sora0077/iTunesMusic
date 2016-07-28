//
//  Review.swift
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


private func getOrCreateCache(collectionId: Int, realm: Realm) -> _ReviewCache {
    if let cache = realm.object(ofType: _ReviewCache.self, forPrimaryKey: collectionId) {
        return cache
    }
    let cache = _ReviewCache()
    cache.collectionId = collectionId
    // swiftlint:disable force_try
    try! realm.write {
        realm.add(cache)
    }
    return cache
}


extension Model {

    public final class Review: Fetchable, FetchableInternal {

        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        private let _changes = PublishSubject<CollectionChange>()

        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
        private(set) var _requestState = Variable<RequestState>(.none)

        private let collectionId: Int

        private let caches: Results<_ReviewCache>

        private var token: NotificationToken!
        private var objectsToken: NotificationToken!

        var needRefresh: Bool {
            return Date() - getOrCreateCache(collectionId: collectionId, realm: iTunesRealm()).refreshAt > 6.hours
        }

        init(collection: iTunesMusic.Collection) {
            collectionId = collection.id

            let realm = iTunesRealm()
            _ = getOrCreateCache(collectionId: collectionId, realm: realm)
            caches = realm.allObjects(ofType: _ReviewCache.self).filter(using: "collectionId = \(collectionId)")
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                func updateObserver(with results: Results<_ReviewCache>) {
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

extension Model.Review {

    func request(refreshing: Bool, force: Bool) {

        if !refreshing && caches[0].fetched {
            _requestState.value = .done
            return
        }

        let collectionId = self.collectionId

        Session.sharedSession.sendRequest(ListReviews<_Review>(id: collectionId), callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let response) where !response.isEmpty:
                let realm = iTunesRealm()
                // swiftlint:disable force_try
                try! realm.write {
                    realm.add(response, update: true)

                    let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
                    cache.page += 1
                    if refreshing {
                        cache.refreshAt = Date()
                        cache.page = 0
                    }
                    self._requestState.value = .done
                }
                tick()
            case .success:
                let realm = iTunesRealm()
                // swiftlint:disable force_try
                try! realm.write {
                    let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
                    cache.fetched = true
                    self._requestState.value = .done
                }
                tick()
            case .failure(let error):
                print(error)
                self._requestState.value = .error
            }
        }
    }
}

extension Model.Review {

    var objects: List<_Review> { return caches[0].objects }
}


extension Model.Review: Swift.Collection {

    public var startIndex: Int { return objects.startIndex }

    public var endIndex: Int { return objects.endIndex }

    public subscript (index: Int) -> Review { return objects[index] }

    public func index(after i: Int) -> Int {
        return objects.index(after: i)
    }
}
