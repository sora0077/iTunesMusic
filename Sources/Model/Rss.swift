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


private func getOrCreateCache(genreId genreId: Int, realm: Realm) -> _RssFeed {
    if let cache = realm.objectForPrimaryKey(_RssFeed.self, key: genreId) {
        return cache
    } else {
        let cache = _RssFeed()
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
    
    private let caches: Results<_RssFeed>
    private var token: NotificationToken!
    private var objectsToken: NotificationToken!
    
    private var trackIds: [Int] = []
    
    public init(genre: Genre) {
        id = genre.id
        url = genre.rssUrls.topSongs
     
        let realm = try! Realm()
        let feed = getOrCreateCache(genreId: id, realm: realm)
        trackIds = feed.items.map { $0.id }
        
        caches = realm.objects(_RssFeed).filter("_genreId = \(id)")
        token = caches.addNotificationBlock { [weak self] changes in
            guard let `self` = self else { return }
            
            func updateObserver(results: Results<_RssFeed>) {
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
        
        
        let ids = trackIds[feed.fetched..<(feed.fetched+10)]
        var lookup = LookupWithIds<LookupResultPage>(ids: Array(ids))
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .Success(let response):
                let realm = try! Realm()
                try! realm.write {
                    realm.add(response.objects, update: true)
                    
                    var done = false
                    let feed = getOrCreateCache(genreId: id, realm: realm)
                    if refreshing {
                        feed.tracks.removeAll()
                    }
                    feed.tracks.appendContentsOf(response.objects)
                    feed.fetched += 10
                    done = feed.items.count == feed.tracks.count
                    self._requestState.value = done ? .done : .none
                }
            case .Failure(let error):
                print(error)
                self._requestState.value = .error
            }
            
        }
    }
    
    private func fetchFeed() {
        
        let id = self.id
        
        let session = Session.sharedSession
        
        session.sendRequest(GetRss<_RssFeed>(url: url, limit: 200)) { [weak self] result in
            guard let `self` = self else { return }
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

extension Rss: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_Track> { return AnyRealmCollection(caches[0].tracks) }
    
    public func _any() -> PlaylistType { return AnyPaginatedPlaylist(playlist: self) }
}

extension Rss: CollectionType {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index] }
}
