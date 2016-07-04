//
//  AlbumCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/02.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


final class _AlbumCache: RealmSwift.Object {
    
    dynamic var collectionId: Int = 0
    
    private dynamic var _collection: _Collection?
    
    dynamic var refreshAt = NSDate.distantPast()
    
    dynamic var createAt = NSDate()
    
    dynamic var fetched: Int = 0
    
    let items = List<_AlbumItem>()
    
    override class func primaryKey() -> String? { return "collectionId" }

    override class func ignoredProperties() -> [String] { return ["collection"] }
    
    var collection: _Collection {
        set {
            _collection = newValue
        }
        get {
            return _collection!
        }
    }
}

final class _AlbumItem: RealmSwift.Object {
    
    dynamic var trackId: Int = 0
}

extension _AlbumCache: Decodable {
    
    static func decode(e: Extractor) throws -> Self {
        func albumItem(trackId: Int) -> _AlbumItem {
            let item = _AlbumItem()
            item.trackId = trackId
            return item
        }
        print(e)
        let items = e.rawValue["items"] as! [[String: AnyObject]]
        
        let obj = self.init()
        obj.items.appendContentsOf(items
            .map { $0["item-id"] as! Int }
            .map(albumItem)
        )
        return obj
    }
}

