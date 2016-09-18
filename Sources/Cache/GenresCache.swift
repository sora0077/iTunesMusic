//
//  GenreCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/20.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


final class _GenresCache: _Cache {

    dynamic var key: String = ""

    let list = List<_Genre>()

    override class func primaryKey() -> String? { return "key" }
}
