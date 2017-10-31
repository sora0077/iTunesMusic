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

private let int = Transformer<String, Int> {
    guard let val = Int($0) else {
        throw DecodeError.typeMismatch(expected: "Int", actual: "String", keyPath: "")
    }
    return val
}

public protocol Genre {
    var name: String { get }
    var id: Int { get }
    var url: URL { get }
    var rssUrls: RssUrls { get }
}

public protocol RssUrls {
    var topAlbums: URL { get }
    var topSongs: URL { get }
}

final class _Genre: RealmSwift.Object {
    @objc fileprivate(set) dynamic var _name: String = ""
    @objc fileprivate(set) dynamic var _id: Int = 0
    @objc fileprivate(set) dynamic var _url: String = ""
    @objc fileprivate(set) dynamic var _rssUrls: _RssUrls?
    @objc fileprivate(set) dynamic var _chartUrls: _ChartUrls?
    fileprivate let _subgenres = List<_Genre>()
    override class func primaryKey() -> String? { return "_id" }
    override class func ignoredProperties() -> [String] {
        return ["name"]
    }
}

extension _Genre: Genre {
    var name: String {
        get { return _name }
        set { _name = newValue }
    }
    var id: Int { return _id }
    var url: URL { return URL(string: _url)! }
    var rssUrls: RssUrls { return _rssUrls! }
}

extension _Genre: Decodable {
    static func decode(_ e: Extractor) throws -> Self {
        let cache = self.init()
        cache._name = try e <| "name"
        cache._id = try int.apply(e <| "id")
        cache._url = try e <| "url"
        cache._rssUrls = try e <|? "rssUrls"
        cache._chartUrls = try e <|? "chartUrls"
        if let subgenres: [String: _Genre] = try e <|-|? "subgenres" {
            cache._subgenres.append(objectsIn: subgenres.values)
        }
        return cache
    }
}

class _RssUrls: RealmSwift.Object {
    @objc dynamic var _topAlbums: String = ""
    @objc dynamic var _topSongs: String = ""
}

extension _RssUrls: RssUrls {
    var topAlbums: URL { return URL(string: _topAlbums)! }
    var topSongs: URL { return URL(string: _topSongs)! }
}

extension _RssUrls: Decodable {
    static func decode(_ e: Extractor) throws -> Self {
        let cache = self.init()
        cache._topAlbums = try e <| "topAlbums"
        cache._topSongs = try e <| "topSongs"
        return cache
    }
}

class _ChartUrls: RealmSwift.Object {
    @objc dynamic var _albums: String = ""
    @objc dynamic var _songs: String = ""
}

extension _ChartUrls: Decodable {
    static func decode(_ e: Extractor) throws -> Self {
        let cache = self.init()
        cache._albums = try e <| "albums"
        cache._songs = try e <| "songs"
        return cache
    }
}
