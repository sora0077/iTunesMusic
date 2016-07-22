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
    if let cache = realm.allObjects(ofType: _HistoryCache.self).first {
        return cache
    } else {
        let cache = _HistoryCache()
        try! realm.write {
            realm.add(cache)
        }
        return cache
    }
}

extension Model {
    
    public final class History: PlaylistType {
        
        public let name = "履歴"
        
        public static let instance = History()
        
        private let _changes = PublishSubject<CollectionChange>()
        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        
        private var objectsToken: NotificationToken?
        private let cache: _HistoryCache
        
        private init() {
            
            let realm = try! iTunesRealm()
            cache = getOrCreateCache(realm: realm)
            objectsToken = cache.objects.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }
                
                self._changes.onNext(CollectionChange(changes))
            }
        }
        
    }
}

extension Model.History {

    public func record(atIndex index: Int) -> (Track, Date) {
        return (objects[index].track, objects[index].createAt)
    }
    
    static func add(_ track: Track, realm: Realm) {
        
        let cache = getOrCreateCache(realm: realm)
        try! realm.write {
            let record = _HistoryRecord(track: track)
            cache.objects.append(record)
        }
    }
    
    static func clearAll() {
        
        let realm = try! iTunesRealm()
        let cache = getOrCreateCache(realm: realm)
        try! realm.write {
            cache.objects.removeAllObjects()
        }
    }
}

extension Model.History: PlayerMiddleware {
    
    public func didEndPlayTrack(_ trackId: Int) {
        let realm = try! iTunesRealm()
        if let track = realm.object(ofType: _Track.self, forPrimaryKey: trackId) {
            Model.History.add(track, realm: realm)
        }
    }
}

extension Model.History: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_HistoryRecord> { return AnyRealmCollection(cache.objects) }
    
    public func _any() -> PlaylistType { return self }
}


extension Model.History: Swift.Collection {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index].track }
    
    public func index(after i: Int) -> Int {
        return objects.index(after: i)
    }
}

