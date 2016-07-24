//
//  RssCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/25.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


class _RssCache: RealmSwift.Object {
    
    dynamic var _genreId: Int = 0
    
    dynamic var _genre: _Genre? {
        didSet {
            print("didSet genre", _genre?.id)
        }
    }
    
    dynamic var refreshAt = Date.distantPast
    
    dynamic var fetched: Int = 0
    
    let items = List<_RssItem>()
    
    let tracks = List<_Track>()
    
    
    override class func primaryKey() -> String? { return "_genreId" }
}

class _RssItem: RealmSwift.Object {
    
    dynamic var id: Int = 0
    
}

extension _RssCache: Decodable {
    
    static func decode(_ e: Extractor) throws -> Self {
        let obj = self.init()
        let entry = e.rawValue["feed"]!!["entry"] as! [[String: AnyObject]]
        let items = entry
            .map { $0["id"]!["attributes"]!!["im:id"] as! String }
            .map { Int($0)! }
            .map { (id) -> _RssItem in
                let item = _RssItem()
                item.id = id
                return item
            }
        obj.items.append(objectsIn: items)
        return obj
    }
}
