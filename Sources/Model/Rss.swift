//
//  Rss.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import RxSwift
import RealmSwift
import Timepiece


extension Array {
    
    subscript (safe range: Range<Index>) -> ArraySlice<Element> {
        return self[min(range.startIndex, count)..<min(range.endIndex, count)]
    }
}


private func getOrCreateCache(genreId genreId: Int, realm: Realm) -> _RssCache {
    if let cache = realm.objectForPrimaryKey(_RssCache.self, key: genreId) {
        return cache
    } else {
        let cache = _RssCache()
        try! realm.write {
            cache._genreId = genreId
            realm.add(cache)
        }
        return cache
    }
}

public final class Rss: PlaylistType, Fetchable, FetchableInternal {
    
    private let _changes = PublishSubject<CollectionChange>()
    public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
    
    public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
    private(set) var _requestState = Variable<RequestState>(.none)
    
    var needRefresh: Bool {
        return NSDate() - getOrCreateCache(genreId: id, realm: try! Realm()).refreshAt > 60.minutes
    }
    
    private let id: Int
    private let url: NSURL
    
    private let caches: Results<_RssCache>
    private var token: NotificationToken!
    private var objectsToken: NotificationToken!
    
    private var trackIds: [Int] = []
    
    public init(genre: Genre) {
        id = genre.id
        url = genre.rssUrls.topSongs
     
        let realm = try! Realm()
        let feed = getOrCreateCache(genreId: id, realm: realm)
        trackIds = feed.items.map { $0.id }
        
        caches = realm.objects(_RssCache).filter("_genreId = \(id)")
        token = caches.addNotificationBlock { [weak self] changes in
            guard let `self` = self else { return }
            
            func updateObserver(results: Results<_RssCache>) {
                self.objectsToken = results[0].tracks.addNotificationBlock { [weak self] changes in
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
            fetchFeed()
            return
        }
        
        let session = Session.sharedSession
        let id = self.id
        
        let realm = try! Realm()
        let feed = getOrCreateCache(genreId: id, realm: realm)
        
        
        let ids = trackIds[safe: feed.fetched..<(feed.fetched+50)]
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
                
                switch result {
                case .Success(let response):
                    let realm = try! Realm()
                    try! realm.write {
                        var tracks: [_Track] = []
                        response.objects.forEach {
                            switch $0 {
                            case .track(let obj):
                                tracks.append(obj)
                                realm.add(obj, update: true)
                            case .collection(let obj):
                                realm.add(obj, update: true)
                            case .artist(let obj):
                                realm.add(obj, update: true)
                            }
                        }
                        
                        var done = false
                        let feed = getOrCreateCache(genreId: id, realm: realm)
                        if refreshing {
                            feed.tracks.removeAll()
                        }
                        feed.tracks.appendContentsOf(tracks)
                        feed.fetched += 50
                        done = feed.items.count == feed.tracks.count
                        self._requestState.value = done ? .done : .none
                    }
                case .Failure(let error):
                    print(error)
                    self._requestState.value = .error
                }
            }
        }
    }
    
    private func fetchFeed() {
        
        let id = self.id
        
        let session = Session.sharedSession
        
        session.sendRequest(GetRss<_RssCache>(url: url, limit: 200)) { [weak self] result in
            guard let `self` = self else { return }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                switch result {
                case .Success(let response):
                    let realm = try! Realm()
                    try! realm.write {
                        let genre = realm.objectForPrimaryKey(_Genre.self, key: id)
                        response._genreId = genre?.id ?? 0
                        response._genre = genre
                        realm.add(response, update: true)
                    }
                    self.trackIds = response.items.map { $0.id }
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

extension Rss: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_Track> { return AnyRealmCollection(caches[0].tracks) }
}

extension Rss: CollectionType {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index] }
}
