//
//  Album.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/02.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Timepiece
import APIKit


private func getOrCreateCache(collectionId: Int, realm: Realm) -> _AlbumCache {
    if let cache = realm.object(ofType: _AlbumCache.self, forPrimaryKey: collectionId) {
        return cache
    }
    let cache = _AlbumCache()
    cache.collectionId = collectionId
    cache.collection = realm.object(ofType: _Collection.self, forPrimaryKey: collectionId)!
    try! realm.write {
        realm.add(cache)
    }
    return cache
}


extension Model {
    
    public final class Album: PlaylistType, Fetchable, FetchableInternal {
        
        private let _changes = PublishSubject<CollectionChange>()
        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        
        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
        private(set) var _requestState = Variable<RequestState>(.none)
        
        var needRefresh: Bool {
            return Date() - getOrCreateCache(collectionId: collectionId, realm: try! iTunesRealm()).refreshAt > 60.minutes
        }
        
        private var objectsToken: NotificationToken?
        private var token: NotificationToken?
        
        private let collectionId: Int
        
        private let caches: Results<_AlbumCache>
        
        public init(collection: Collection) {
            
            let collection = collection as! _Collection
            self.collectionId = collection._collectionId
            
            let realm = try! iTunesRealm()
            let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
            caches = realm.allObjects(ofType: _AlbumCache.self).filter(using: "collectionId = \(collectionId)")
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }
                
                func updateObserver(with results: Results<_AlbumCache>) {
                    self.objectsToken = results[0].collection
                        ._tracks
                        .sorted(with: [
                            SortDescriptor(property: "_discNumber", ascending: true),
                            SortDescriptor(property: "_trackNumber", ascending: true)
                        ])
                        .addNotificationBlock { [weak self] changes in
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

extension Model.Album {
    
    public var collection: Collection {
        return caches[0].collection
    }
}

extension Model.Album: CustomStringConvertible {
    
    public var description: String {
        if Thread.isMainThread {
            return "\(Mirror(reflecting: self))) \(collection.name)"
        }
        return "\(Mirror(reflecting: self)))"
    }
}

extension Model.Album {
    
    func request(refreshing: Bool, force: Bool) {
        
        let collectionId = self.collectionId
        let cache = getOrCreateCache(collectionId: collectionId, realm: try! iTunesRealm())
        if !refreshing && cache.collection._trackCount == cache.collection._tracks.count {
            _requestState.value = .done
            return
        }
        
        let session = Session.sharedSession
        
        var lookup = LookupWithIds<LookupResponse>(id: collectionId)
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let response):
                let realm = try! iTunesRealm()
                try! realm.write {
                    response.objects.reversed().forEach {
                        switch $0 {
                        case .track(let obj):
                            realm.add(obj, update: true)
                        case .collection(let obj):
                            realm.add(obj, update: true)
                        case .artist(let obj):
                            realm.add(obj, update: true)
                        }
                    }
                    
                    let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
                    if refreshing {
                        cache.refreshAt = Date()
                    }
                    print(cache.collection._trackCount, cache.collection._tracks.count)
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

extension Model.Album: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_Track> {
        return AnyRealmCollection(caches[0].collection._tracks.sorted(with: [
            SortDescriptor(property: "_discNumber", ascending: true),
            SortDescriptor(property: "_trackNumber", ascending: true)
        ]))
    }
}

extension Model.Album: Swift.Collection {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index] }
    
    public func index(after i: Int) -> Int {
        return objects.index(after: i)
    }
}
