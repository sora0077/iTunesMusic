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


final class _HistoryCache: _Cache {

    let objects = List<_HistoryRecord>()

    private(set) lazy var sortedObjects: Results<_HistoryRecord> = self.objects.sorted(byProperty: "createAt", ascending: false)
}
