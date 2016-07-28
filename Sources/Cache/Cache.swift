//
//  Cache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/28.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


class _Cache: RealmSwift.Object {

    dynamic var refreshAt = Date.distantPast

    dynamic var createAt = Date()
}
