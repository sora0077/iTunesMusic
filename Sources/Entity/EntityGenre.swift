//
//  Genre.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/23.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


let int = Transformer<String, Int> {
    guard let val = Int($0) else {
        throw DecodeError.TypeMismatch(expected: "Int", actual: "String", keyPath: "")
    }
    return val
}

public protocol Genre {
    
    var name: String { get }
    
    var id: Int { get }
    
    var url: NSURL { get }
    
    var rssUrls: RssUrls { get }
}

public protocol RssUrls {
    
    var topAlbums: NSURL { get }
    
    var topSongs: NSURL { get }
}

class _Genre: RealmSwift.Object {
    
    dynamic var _name: String = ""
    
    dynamic var _id: Int = 0
    
    dynamic var _url: String = ""
    
    dynamic var _rssUrls: _RssUrls?
    
    dynamic var _chartUrls: _ChartUrls?
    
    let _subgenres = List<_Genre>()
    
    override class func primaryKey() -> String? { return "_id" }
}

extension _Genre: Genre {
    
    var name: String { return _name }
    
    var id: Int { return _id }
    
    var url: NSURL { return NSURL(string: _url)! }
    
    var rssUrls: RssUrls { return _rssUrls! }
}

extension _Genre: Decodable {
    
    static func decode(e: Extractor) throws -> Self {
        let cache = self.init()
        cache._name = try e <| "name"
        cache._id = try int.apply(e <| "id")
        cache._url = try e <| "url"
        cache._rssUrls = try e <|? "rssUrls"
        cache._chartUrls = try e <|? "chartUrls"
        if let subgenres: [String: _Genre] = try e <|-|? "subgenres" {
            cache._subgenres.appendContentsOf(subgenres.values)
        }
        return cache
    }
}

class _RssUrls: RealmSwift.Object {
    
    dynamic var _topAlbums: String = ""
    
    dynamic var _topSongs: String = ""
}

extension _RssUrls: RssUrls {
    
    var topAlbums: NSURL { return NSURL(string: _topAlbums)! }
    
    var topSongs: NSURL { return NSURL(string: _topSongs)! }
}

extension _RssUrls: Decodable {
    
    static func decode(e: Extractor) throws -> Self {
        
        let cache = self.init()
        cache._topAlbums = try e <| "topAlbums"
        cache._topSongs = try e <| "topSongs"
        return cache
    }
}


class _ChartUrls: RealmSwift.Object {
    
    dynamic var _albums: String = ""
    
    dynamic var _songs: String = ""
    
}

extension _ChartUrls: Decodable {
    
    static func decode(e: Extractor) throws -> Self {
        
        let cache = self.init()
        cache._albums = try e <| "albums"
        cache._songs = try e <| "songs"
        return cache
    }
}
