//
//  Search.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import APIKit
import Timepiece


private func getOrCreateCache(term term: String, realm: Realm) -> SearchCache {
    if let cache = realm.objectForPrimaryKey(SearchCache.self, key: term) {
        return cache
    } else {
        let cache = SearchCache()
        try! realm.write {
            cache.term = term
            realm.add(cache)
        }
        return cache
    }
}


public final class Search: PlaylistType, PaginatorTypeInternal, PaginatorType {
    
    var name: String { return term }
    
    var hasNoPaginatedContents: Bool {
        return [.Done, .Error].contains(_requestState.value)
    }
    
    private let _changes = PublishSubject<CollectionChange>()
    public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
    
    private let _requestState = Variable<RequestState>(.None)
    public private(set) lazy var requestState: Observable<RequestState> = asReplayObservable(self._requestState)
    
    private let _refreshing = Variable<Bool>(false)
    
    

    private let term: String
    private let caches: Results<SearchCache>
    private var token: NotificationToken!
    private var objectsToken: NotificationToken?
    
    public init(term: String) {
        self.term = term
        
        let realm = try! Realm()
        getOrCreateCache(term: term, realm: realm)
        caches = realm.objects(SearchCache).filter("term = %@", term)
        token = caches.addNotificationBlock { [weak self] changes in
            guard let `self` = self else { return }
            
            func updateObserver(results: Results<SearchCache>) {
                self.objectsToken = results[0].objects.addNotificationBlock { [weak self] changes in
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
    
    public func fetch() {
        
        print("fetch")
        request()
    }
    
    public func refresh(force force: Bool) {
        
        if force || NSDate() - getOrCreateCache(term: term, realm: try! Realm()).refreshAt > 60.minutes {
            request(refreshing: true)
        }
    }
    
    private func request(refreshing refreshing: Bool = false) {
        
        if [.Requesting, .Done].contains(_requestState.value) {
            return
        }
        
        _refreshing.value = refreshing
        _requestState.value = .Requesting
        
        let session = Session(adapter: NSURLSessionAdapter(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()))
        
        var search: SearchWithKeyword<SearchResultPage>
        if refreshing {
            search = SearchWithKeyword(term: term)
        } else {
            let realm = try! Realm()
            search = SearchWithKeyword(term: term, offset: getOrCreateCache(term: term, realm: realm).offset)
        }
        search.lang = "ja_JP"
        search.country = "JP"
        session.sendRequest(search) { [weak self] result in
            guard let `self` = self else { return }
            
            defer {
                self._refreshing.value = false
                tick()
            }
            switch result {
            case .Success(let results):
                let realm = try! Realm()
                let cache = getOrCreateCache(term: self.term, realm: realm)
                try! realm.write {
                    realm.add(results.objects, update: true)
                    if refreshing {
                        cache.objects.removeAll()
                        cache.refreshAt = NSDate()
                    }
                    cache.objects.appendContentsOf(results.objects)
                    cache.updateAt = NSDate()
                    cache.offset += results.objects.count
                }
                print("search result cached")
                self._requestState.value = results.objects.count != search.limit ? .Done : .None
                print(self._requestState.value)
            case .Failure(let error):
                print(error)
                self._requestState.value = .Error
            }
        }
    }
}


extension Search: PlaylistTypeInternal {
    
    var objects: List<_Track> { return caches[0].objects }
    
    func track(atIndex index: Int) -> Track { return objects[index] }
}

extension Search: CollectionType {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return track(atIndex: index) }
}
