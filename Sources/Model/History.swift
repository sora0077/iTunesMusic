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


private func getOrCreateCache(realm realm: Realm) -> HistoryCache {
    if let cache = realm.objects(HistoryCache.self).first {
        return cache
    } else {
        let cache = HistoryCache()
        try! realm.write {
            realm.add(cache)
        }
        return cache
    }
}


public final class History: PlaylistType, PlaylistTypeInternal {
    
    var objects: List<_HistoryRecord> {
        return cache.objects
    }
    
    public let name = "履歴"
    
    public var count: Int { return objects.count }
    
    private let _changes = PublishSubject<CollectionChange>()
    public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
    
    private var objectsToken: NotificationToken?
    private let cache: HistoryCache
    
    private init() {
        
        let realm = try! Realm()
        cache = getOrCreateCache(realm: realm)
        objectsToken = cache.objects.addNotificationBlock { [weak self] changes in
            guard let `self` = self else { return }
            
            self._changes.onNext(CollectionChange(changes))
        }
    }
    
    public func track(atIndex index: Int) -> Track {
        return self.objects[index].track
    }
    
    public func addInto(player player: Player) {
        player.addPlaylist(self)
    }
    
    public static let instance = History()
    
    static func add(track: Track, realm: Realm) {
        
        let cache = getOrCreateCache(realm: realm)
        try! realm.write {
            let record = _HistoryRecord(track: track)
            cache.objects.append(record)
        }
    }
    
    static func clearAll() {
        
        let realm = try! Realm()
        let cache = getOrCreateCache(realm: realm)
        try! realm.write {
            cache.objects.removeAll()
        }
    }
}


