//
//  History.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/13.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift


private func getOrCreateCache(realm: Realm) -> _HistoryCache {
    if let cache = realm.objects(_HistoryCache.self).first {
        return cache
    } else {
        let cache = _HistoryCache()
        // swiftlint:disable force_try
        try! realm.write {
            realm.add(cache)
        }
        return cache
    }
}


extension Model {

    public final class History: ObservableList, _ObservableList {

        public let name = "履歴"

        public static let shared = History()

        private var objectsToken: NotificationToken?
        fileprivate let cache: _HistoryCache

        fileprivate init() {

            let realm = iTunesRealm()
            cache = getOrCreateCache(realm: realm)
            objectsToken = cache.sortedObjects.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }

                self._changes.onNext(CollectionChange(changes))
            }
        }

    }
}

extension Model.History: PlayerMiddleware {

    public func didEndPlayTrack(_ trackId: Int) {
        let realm = iTunesRealm()
        let cache = getOrCreateCache(realm: realm)
        if let track = realm.object(ofType: _Track.self, forPrimaryKey: trackId) {
            try! realm.write {
                cache.add(track: track)
            }
        }
    }
}


extension Model.History: Swift.Collection, PlaylistType {

    private var objects: Results<_HistoryRecord> {
        return cache.sortedObjects
    }

    public var count: Int { return trackCount }

    public var isEmpty: Bool { return isTrackEmpty }

    public var startIndex: Int { return objects.startIndex }

    public var endIndex: Int { return objects.endIndex }

    public subscript (index: Int) -> (Track, Date) { let r = objects[index]; return (r.track, r.createAt) }

    public func index(after i: Int) -> Int {
        return objects.index(after: i)
    }


    public var trackCount: Int { return objects.count }

    public var isTrackEmpty: Bool { return objects.isEmpty }

    public func track(at index: Int) -> Track { return objects[index].track }
}
