//
//  HistoryRecord.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/16.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Himotoki


class _HistoryRecord: RealmSwift.Object {
    
    private dynamic var _track: _Track?
    
    private(set) dynamic var createAt: NSDate = NSDate()

    var track: Track { return _track! }
}

extension _HistoryRecord {
    
    convenience init(track: Track) {
        self.init()
        let track = track as! _Track
        _track = track
    }
    
}
