//
//  SearchCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Himotoki


class _SearchCache: _Cache, SearchWithKeywordResponseType {

    let objects = List<_Media>()

    dynamic var term: String = ""

    dynamic var offset: Int = 0

    override class func primaryKey() -> String? { return "term" }
}
