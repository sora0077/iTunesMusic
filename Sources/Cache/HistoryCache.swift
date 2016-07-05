//
//  HistoryCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/13.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Himotoki


class _HistoryCache: RealmSwift.Object {
    
    let objects = List<_HistoryRecord>()
    
    dynamic var createAt: NSDate = NSDate()
    
    dynamic var updateAt: NSDate = NSDate()
}

