//
//  DiskCacheCounter.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

final class _DiskCacheCounter: _Cache {

    dynamic var trackId = 0

    dynamic var counter = 0

    override class func primaryKey() -> String? { return "trackId" }
}
