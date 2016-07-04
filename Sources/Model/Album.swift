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
    private let url: NSURL
    
    private let caches: Results<_AlbumCache>
    
    private var trackIds: [Int] = []
    
    public init(collection: Collection) {
        
        let collection = collection as! _Collection
        self.collectionId = collection._collectionId
        url = NSURL(string: collection._collectionViewUrl)!
        let realm = try! Realm()
        let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
        trackIds = cache.items.map { $0.trackId }
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
    
    func request(refreshing refreshing: Bool) {
        
        if trackIds.isEmpty || refreshing {
            fetchIds()
            return
        }
        
        let session = Session.sharedSession
        let collectionId = self.collectionId
        
        let realm = try! Realm()
        let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
        
        
        let ids = trackIds[safe: cache.fetched..<(cache.fetched+50)]
        if ids.isEmpty {
            _requestState.value = .done
            return
        }
        var lookup = LookupWithIds<LookupResponse>(ids: Array(ids))
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup) { [weak self] result in
            guard let `self` = self else { return }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                print(result)
                switch result {
                case .Success(let response):
                    let realm = try! Realm()
                    try! realm.write {
                        response.objects.forEach {
                            switch $0 {
                            case .song(let obj):
                                realm.add(obj, update: true)
                            case .collection(let obj):
                                realm.add(obj, update: true)
                            case .artist(let obj):
                                realm.add(obj, update: true)
                            }
                        }
                        
                        let cache = getOrCreateCache(collectionId: collectionId, realm: realm)
                        cache.fetched += 50
                        let done = cache.items.count == cache.collection._tracks.count
                        self._requestState.value = done ? .done : .none
                    }
                case .Failure(let error):
                    print(error)
                    self._requestState.value = .error
                }
            }
        }
    }
    
    private func fetchIds() {
        
        let collectionId = self.collectionId
        
        let session = Session.sharedSession
        session.sendRequest(GetAlbumTracks<_AlbumCache>(url: url)) { [weak self] result in
            
            guard let `self` = self else { return }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                switch result {
                case .Success(let response):
                    let realm = try! Realm()
                    try! realm.write {
                        let collection = realm.objectForPrimaryKey(_Collection.self, key: collectionId)!
                        response.collection = collection
                        response.collectionId = collectionId
                        realm.add(response, update: true)
                    }
                    self.trackIds = response.items.map { $0.trackId }
                    self._requestState.value = .none
                    self.request(refreshing: false)
                case .Failure(let error):
                    print(error)
                    self._requestState.value = .error
                }
            }
        }
    }
}

extension Album: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_Track> { return AnyRealmCollection(caches[0].collection._tracks.sorted("_trackNumber")) }
    
    public func _any() -> PlaylistType { return AnyPaginatedPlaylist(playlist: self) }
}

extension Album: CollectionType {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index] }
}
