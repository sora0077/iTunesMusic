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

private var _requestState = Variable<RequestState>(.none)


public final class Genres {
    
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
    
    public private(set) lazy var requestState: Observable<RequestState> = asObservable(_requestState)
    
    private var token: NotificationToken?
    private var objectsToken: NotificationToken?
    private let caches: Results<_GenresCache>
    private var cache: _GenresCache {
        return caches[0]
    }
    
    public init() {
        
        let realm = try! Realm()
        caches = realm.objects(_GenresCache).filter("key = %@", "default").sorted("createAt", ascending: false)
        if caches.isEmpty {
            try! realm.write {
                let defaults = _GenresCache()
                defaults.key = "default"
                realm.add(defaults)
            }
        }
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
    
    public func fetch() {
        
        if [.requesting, .done].contains(_requestState.value) {
            return
        }
        
        let session = Session(adapter: NSURLSessionAdapter(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()))
        
        var listGenres = ListGenres<_Genre>()
        listGenres.country = "jp"
        session.sendRequest(listGenres) { result in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                switch result {
                case .Success(let cache):
                    let realm = try! Realm()
                    try! realm.write {
                        realm.add(cache, update: true)
                        
                        let defaults = _GenresCache()
                        defaults.key = "default"
                        for genre in InitialDefaultGenre.cases {
                            defaults.list.append(realm.objectForPrimaryKey(_Genre.self, key: genre.rawValue)!)
                        }
                        realm.add(defaults)
                    }
                    _requestState.value = .done
                case .Failure(let error):
                    print(error)
                    _requestState.value = .error
                }
            }
        }
    }
}

extension Genres: CollectionType {
    
    public var startIndex: Int { return isEmpty ? 0 : cache.list.startIndex }
    
    public var endIndex: Int { return isEmpty ? 0 : cache.list.endIndex }
    
    public subscript (index: Int) -> Genre {
        return cache.list[index]
    }
}
