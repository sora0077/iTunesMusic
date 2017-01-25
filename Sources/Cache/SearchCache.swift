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

final class _SearchCache: _Cache, SearchWithKeywordResponseType {

    let objects = List<_Media>()

    dynamic var term: String = ""

    dynamic var offset: Int = 0

    override class func primaryKey() -> String? { return "term" }
}

final class _SearchTrendsCache: _Cache {

    fileprivate dynamic var id: Int = 0

    dynamic var name: String = ""

    fileprivate dynamic var _trendings: String = ""

    override class func primaryKey() -> String? { return "id" }

    override class func ignoredProperties() -> [String] {
        return ["trendings"]
    }

    var trendings: [String] {
        set {
            _trendings = newValue.joined(separator: "\t")
        }
        get {
            return _trendings.components(separatedBy: "\t").filter { $0 != "" }
        }
    }
}
