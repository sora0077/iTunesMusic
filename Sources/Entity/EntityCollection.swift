//
//  Collection.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/02.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


public protocol Collection {

    subscript (index: Int) -> Track { get }
    
    func artworkURL(size size: Int) -> NSURL
}


class _Collection: RealmSwift.Object, Collection {
    
    dynamic var _collectionId: Int = 0
    dynamic var _collectionName: String = ""
    dynamic var _collectionCensoredName: String = ""
    dynamic var _collectionViewUrl: String = ""
    let _collectionPrice = RealmOptional<Float>()
    dynamic var _collectionExplicitness: String = ""
    
    dynamic var _artworkUrl60: String = ""
    dynamic var _artworkUrl100: String = ""
    
    dynamic var _trackCount: Int = 0
    
    dynamic var _artist: _Artist?
    
    let _tracks = LinkingObjects(fromType: _Track.self, property: "_collection")
    
    override class func primaryKey() -> String? { return "_collectionId" }
}

extension _Collection: CollectionType {
    
    var startIndex: Int { return _tracks.startIndex }
    
    var endIndex: Int { return _tracks.endIndex }
    
    subscript (index: Int) -> Track {
        return _tracks.sorted([
            SortDescriptor(property: "_trackNumber")
        ])[index]
    }
}

extension _Collection: Decodable {
    
    static func decode(e: Extractor) throws -> Self {
        
        let obj = self.init()
        obj._collectionId = try e.value("collectionId")
        obj._collectionName = try e.value("collectionName")
        obj._collectionCensoredName = try e.value("collectionCensoredName")
        obj._collectionViewUrl = try e.value("collectionViewUrl")
        obj._collectionPrice.value = try e.valueOptional("collectionPrice")
        obj._collectionExplicitness = try e.value("collectionExplicitness")
        
        obj._artworkUrl60 = try e.value("artworkUrl60")
        obj._artworkUrl100 = try e.value("artworkUrl100")
        
        obj._trackCount = try e.value("trackCount")
        
        let artist: _Artist = try _Artist.collectionArtist(e) ?? Himotoki.decodeValue(e.rawValue)
        obj._artist = artist
        return obj
    }
}


private let artworkRegex = try! NSRegularExpression(pattern: "[1-9]00x[1-9]00", options: [])
private let artworkCached = NSCache()

extension _Collection {
    
    func artworkURL(size size: Int) -> NSURL {
        let base = _artworkUrl100
        let key = "\(base)_____\(size)"
        if let url = artworkCached.objectForKey(key) as? NSURL {
            return url
        }
        
        let replaced = artworkRegex.stringByReplacingMatchesInString(
            base,
            options: [],
            range: NSMakeRange(0, base.utf16.count),
            withTemplate: "\(size)x\(size)"
        )
        let url = NSURL(string: replaced)!
        artworkCached.setObject(url, forKey: key)
        return url
    }
}
