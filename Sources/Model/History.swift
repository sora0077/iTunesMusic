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


final class History: PlaylistType {
    
    var objects: List<HistoryCacheToken> {
        return cache.objects
    }
    
    let name = "履歴"
    
    private let _changes = PublishSubject<CollectionChange>()
    private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
    
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
    
    static let instance = History()
    
    static func add(track: Track, realm: Realm) {
        
        let track = track as! _Track
        let cache = getOrCreateCache(realm: realm)
        try! realm.write {
            let token = HistoryCacheToken()
            token._track = track
            cache.objects.append(token)
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

extension History {
    
    func get(index: Int) -> (Track, NSDate) {
        let token = objects[index]
        return (token._track as! Track, token.createAt)
    }
    
}

extension History: CollectionType {
    
    var startIndex: Int { return objects.startIndex }
    
    var endIndex: Int { return objects.endIndex }
    
    subscript (index: Int) -> Track {
        return get(index).0
    }
    
}
