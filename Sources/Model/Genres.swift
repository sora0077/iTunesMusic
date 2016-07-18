//
//  Genres.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/20.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import APIKit
import Timepiece


private var __requestState = Variable<RequestState>(.none)

private func getOrCreateCache(key key: String, realm: Realm) -> _GenresCache {
    if let cache = realm.objectForPrimaryKey(_GenresCache.self, key: key) {
        return cache
    } else {
        let cache = _GenresCache()
        cache.key = key
        try! realm.write {
            realm.add(cache)
        }
        return cache
    }
}

extension Model {
    
    public final class Genres: Fetchable, FetchableInternal {
        
        private enum InitialDefaultGenre: Int {
            
            case top = 34
            
            case jpop = 27
            case anime = 29
            
            case electronic = 7
            
            case disney = 50000063
            
            case sountTrack = 16
            case jazz = 11
            
            static var cases: [InitialDefaultGenre] {
                return [
                    .top, .jpop, .anime, .electronic, .disney, .sountTrack, .jazz
                ]
            }
        }
        
        public var isEmpty: Bool { return caches.isEmpty || cache.list.isEmpty }
        
        private let _changes = PublishSubject<CollectionChange>()
        public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
        
        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
        var _requestState: Variable<RequestState> { return __requestState }
        
        var needRefresh: Bool { return NSDate() - getOrCreateCache(key: "default", realm: try! iTunesRealm()).refreshAt > 30.days }
        
        private var token: NotificationToken?
        private var objectsToken: NotificationToken?
        private let caches: Results<_GenresCache>
        private var cache: _GenresCache {
            return caches[0]
        }
        
        public init() {
            
            let realm = try! iTunesRealm()
            getOrCreateCache(key: "default", realm: realm)
            caches = realm.objects(_GenresCache).filter("key == %@", "default").sorted("createAt", ascending: false)
            token = caches.addNotificationBlock { [weak self] changes in
                guard let `self` = self else { return }
                
                func updateObserver(results: Results<_GenresCache>) {
                    self.objectsToken = results[0].list.addNotificationBlock { [weak self] changes in
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

extension Model.Genres {
    
    func request(refreshing refreshing: Bool, force: Bool) {
        
        if !refreshing && !caches[0].list.isEmpty {
            _requestState.value = .done
            return
        }
        
        let session = Session(adapter: NSURLSessionAdapter(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()))
        
        var listGenres = ListGenres<_Genre>()
        listGenres.country = "jp"
        session.sendRequest(listGenres, callbackQueue: callbackQueue) { result in
            switch result {
            case .Success(let cache):
                let realm = try! iTunesRealm()
                try! realm.write {
                    realm.add(cache, update: true)
                    
                    let cache = getOrCreateCache(key: "default", realm: realm)
                    if refreshing {
                        cache.list.removeAll()
                        cache.refreshAt = NSDate()
                    }
                    
                    for genre in InitialDefaultGenre.cases {
                        cache.list.append(realm.objectForPrimaryKey(_Genre.self, key: genre.rawValue)!)
                    }
                    realm.add(cache)
                }
                __requestState.value = .done
            case .Failure(let error):
                print(error)
                __requestState.value = .error
            }
        }
    }
}

extension Model.Genres: CollectionType {
    
    public var startIndex: Int { return isEmpty ? 0 : cache.list.startIndex }
    
    public var endIndex: Int { return isEmpty ? 0 : cache.list.endIndex }
    
    public subscript (index: Int) -> Genre {
        return cache.list[index]
    }
}
