//
//  Artist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/04.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import APIKit
import Timepiece
import Himotoki


private func getOrCreateCache(artistId artistId: Int, realm: Realm) -> _ArtistCache {
    if let cache = realm.objectForPrimaryKey(_ArtistCache.self, key: artistId) {
        return cache
    }
    let cache = _ArtistCache()
    cache.artistId = artistId
    cache.artist = realm.objectForPrimaryKey(_Artist.self, key: artistId)!
    try! realm.write {
        realm.add(cache)
    }
    return cache
}

extension Model {
    
    public final class Artist: Fetchable, FetchableInternal {
        
        private let _changes = PublishSubject<CollectionChange>()
        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        
        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
        private(set) var _requestState = Variable<RequestState>(.none)
        
        var needRefresh: Bool {
            return NSDate() - getOrCreateCache(artistId: artistId, realm: try! iTunesRealm()).refreshAt > 60.minutes
        }
        
        private var objectsToken: NotificationToken?
        private var token: NotificationToken?
        
        private let artistId: Int
        
        private let caches: Results<_ArtistCache>
        
        public init(artist: iTunesMusic.Artist) {
            
            let artist = artist as! _Artist
            self.artistId = artist._artistId
            
            let realm = try! iTunesRealm()
            let cache = getOrCreateCache(artistId: artistId, realm: realm)
            caches = realm.objects(_ArtistCache).filter("artistId = \(artistId)")
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }
                
                func updateObserver(results: Results<_ArtistCache>) {
                    self.objectsToken = results[0].artist._collections.sorted("_collectionId", ascending: false).addNotificationBlock { [weak self] changes in
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

extension Model.Artist {
    
    func request(refreshing refreshing: Bool, force: Bool) {
        
        let artistId = self.artistId
        let cache = getOrCreateCache(artistId: artistId, realm: try! iTunesRealm())
        if !refreshing && cache.fetched {
            return
        }
        
        let session = Session.sharedSession
        
        var lookup = LookupWithIds<LookupResponse>(id: artistId)
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup) { [weak self] result in
            guard let `self` = self else { return }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                switch result {
                case .Success(let response):
                    let realm = try! iTunesRealm()
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
                        
                        let cache = getOrCreateCache(artistId: artistId, realm: realm)
                        cache.fetched = true
                        if refreshing {
                            cache.refreshAt = NSDate()
                        }
                        self._requestState.value = .done
                    }
                case .Failure(let error):
                    print(error)
                    self._requestState.value = .error
                }
            }
        }
    }
}

extension Model.Artist {
    
    var objects: AnyRealmCollection<_Collection> { return AnyRealmCollection(caches[0].artist._collections.sorted("_collectionId", ascending: false)) }
}

extension Model.Artist: CollectionType {
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Collection { return objects[index] }
}
