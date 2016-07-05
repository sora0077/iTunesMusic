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


private func getOrCreateCache(collectionId collectionId: Int, realm: Realm) -> _AlbumCache {
    if let cache = realm.objectForPrimaryKey(_AlbumCache.self, key: collectionId) {
        return cache
    }
    let cache = _AlbumCache()
    cache.collectionId = collectionId
    cache.collection = realm.objectForPrimaryKey(_Collection.self, key: collectionId)!
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
            return NSDate() - getOrCreateCache(collectionId: collectionId, realm: try! Realm()).refreshAt > 60.minutes
        }
        
        private var objectsToken: NotificationToken?
        private var token: NotificationToken?
        
        private let collectionId: Int
        
        private let caches: Results<_AlbumCache>
        
        public init(collection: Collection) {
            
            let collection = collection as! _Collection
            self.collectionId = collection._collectionId
            
            let realm = try! Realm()
            let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
            caches = realm.objects(_AlbumCache).filter("collectionId = \(collectionId)")
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }
                
                func updateObserver(results: Results<_AlbumCache>) {
                    self.objectsToken = results[0].collection._tracks.sorted("_trackNumber").addNotificationBlock { [weak self] changes in
                        self?._changes.onNext(CollectionChange(changes))
                    }
                }
                
                switch changes {
                case .Initial(let results):
                    updateObserver(results)
                case .Update(let results, deletions: _, insertions: let insertions, modifications: _):
                    if !insertions.isEmpty {
                        updateObserver(results)
                    }
                case .Error(let error):
                    fatalError("\(error)")
                }
            }
        }
    }
}

extension Model.Album {

    func request(refreshing refreshing: Bool) {
        
        let collectionId = self.collectionId
        let cache = getOrCreateCache(collectionId: collectionId, realm: try! Realm())
        if !refreshing && cache.collection._trackCount == cache.collection._tracks.count {
            return
        }
        
        let session = Session.sharedSession
        
        var lookup = LookupWithIds<LookupResponse>(id: collectionId)
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup) { [weak self] result in
            guard let `self` = self else { return }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                switch result {
                case .Success(let response):
                    let realm = try! Realm()
                    try! realm.write {
                        response.objects.forEach {
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
                        let done = cache.collection._trackCount == cache.collection._tracks.count
                        self._requestState.value = done ? .done : .none
                    }
                case .Failure(let error):
                    print(error)
                    self._requestState.value = .error
                }
            }
        }
    }
}

extension Model.Album: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_Track> { return AnyRealmCollection(caches[0].collection._tracks.sorted("_trackNumber")) }
    
    public func _any() -> PlaylistType { return AnyPaginatedPlaylist(playlist: self) }
}

extension Model.Album: CollectionType {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index] }
}
