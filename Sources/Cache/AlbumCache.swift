//
//  AlbumCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/02.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


final class _AlbumCache: _Cache {

    dynamic var collectionId: Int = 0

    fileprivate dynamic var _collection: _Collection?

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
