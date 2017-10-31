//
//  EntityPlaylist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

public protocol MyPlaylist {
    var title: String { get }
}

extension MyPlaylist {
    var impl: _MyPlaylist {
        // swiftlint:disable:next force_cast
        return self as! _MyPlaylist
    }
}

@objc
final class _MyPlaylist: RealmSwift.Object, MyPlaylist {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title = ""
    let tracks = List<_Track>()
    @objc fileprivate(set) dynamic var createAt = Date()
    @objc dynamic var updateAt = Date()

}
