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

    @objc dynamic var trackId = 0

    @objc dynamic var counter = 0

    override class func primaryKey() -> String? { return "trackId" }
}
