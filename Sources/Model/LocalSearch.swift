
//
//  LocalSearch.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/19.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift


public final class LocalSearch: PlaylistType {
    
    var name: String { return term }
    
    private let results: Results<_Track>
    
    private let _changes = PublishSubject<CollectionChange>()
    public private(set) lazy var changes: Observable<CollectionChange> = asObservable(self._changes)
    
    private var token: NotificationToken!
    
    private let term: String
    
    public init(term: String) {
        self.term = term
        
        let realm = try! Realm()
        results = realm.objects(_Track).filter("_trackName = %@", term).sorted("_createAt", ascending: false)
        token = objects.addNotificationBlock { [weak self] changes in
            guard let `self` = self else { return }
            
            self._changes.onNext(CollectionChange(changes))
        }
    }
}

extension LocalSearch: PlaylistTypeInternal {
    
    var objects: AnyRealmCollection<_Track> { return AnyRealmCollection(results) }
    
    public func _any() -> PlaylistType { return AnyPlaylist(playlist: self) }
}

extension LocalSearch: CollectionType {
    
    public var count: Int { return objects.count }
    
    public var isEmpty: Bool { return objects.isEmpty }
    
    public var startIndex: Int { return objects.startIndex }
    
    public var endIndex: Int { return objects.endIndex }
    
    public subscript (index: Int) -> Track { return objects[index] }
}
