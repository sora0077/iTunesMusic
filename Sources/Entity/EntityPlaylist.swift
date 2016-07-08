//
//  EntityPlaylist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


final class MyPlaylist: RealmSwift.Object {

    dynamic var id = NSUUID().UUIDString
    
    dynamic var title = ""
    
    let tracks = List<_Track>()
    
    dynamic var createAt = NSDate()
    
    dynamic var updateAt = NSDate()

}

