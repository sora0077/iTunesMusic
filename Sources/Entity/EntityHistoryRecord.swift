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

final class _HistoryRecord: RealmSwift.Object {
    @objc fileprivate dynamic var _track: _Track?
    @objc fileprivate(set) dynamic var createAt: Date = Date()
    var track: Track { return _track! }
}

extension _HistoryRecord {
    convenience init(track: Track) {
        self.init()
        _track = track.impl
    }

}
