//
//  ArtistCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/05.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


final class _ArtistCache: RealmSwift.Object {
    
    dynamic var artistId: Int = 0
    
    private dynamic var _artist: _Artist?
    
    dynamic var refreshAt = NSDate.distantPast()
    
    dynamic var createAt = NSDate()
    
    dynamic var fetched = false
    
    override class func primaryKey() -> String? { return "artistId" }
    
    override class func ignoredProperties() -> [String] { return ["artist"] }
    
    var artist: _Artist {
        set {
            _artist = newValue
        }
        get {
            return _artist!
        }
    }
}
