//
//  ReviewCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/28.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

final class _ReviewCache: _Cache {

    dynamic var collectionId: Int = 0

    dynamic var fetched: Bool = false

    dynamic var page: Int = 1

    let objects = List<_Review>()

    override class func primaryKey() -> String? { return "collectionId" }
}
