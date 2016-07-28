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
        // swiftlint:disable force_cast
        return self as! _MyPlaylist
    }
}


final class _MyPlaylist: RealmSwift.Object, MyPlaylist {

    dynamic var id = UUID().uuidString

    dynamic var title = ""

    let tracks = List<_Track>()

    private(set) dynamic var createAt = Date()

    dynamic var updateAt = Date()

}
