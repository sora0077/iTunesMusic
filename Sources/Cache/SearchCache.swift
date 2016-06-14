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


class SearchCache: RealmSwift.Object, SearchWithKeywordResponseType {
    
    let objects = List<_Track>()
    
    dynamic var createAt: NSDate = NSDate()
    
    dynamic var updateAt: NSDate = NSDate()
    
    dynamic var refreshAt: NSDate = NSDate()
    
    dynamic var term: String = ""
    
    dynamic var offset: Int = 0
    
    override class func primaryKey() -> String? { return "term" }
}
