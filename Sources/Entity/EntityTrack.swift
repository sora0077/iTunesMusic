//
//  Track.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/05.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


public protocol EntityInterface {
    
}


public protocol Track: EntityInterface {
    
    var trackId: Int { get }

    var trackName: String { get }
    
    var trackViewURL: NSURL { get }
    
    var collection: Collection { get }
    
    var artist: Artist { get }
    
    var cached: Bool { get }
    
    func artworkURL(size size: Int) -> NSURL
}


class _Track: RealmSwift.Object, Track {
    
    dynamic var _trackId: Int = 0
    dynamic var _trackName: String = ""
    dynamic var _trackCensoredName: String = ""
    dynamic var _trackViewUrl: String = ""
    dynamic var _trackPrice: Float = 0
    dynamic var _trackExplicitness: String = ""
    dynamic var _trackCount: Int = 0
    dynamic var _trackNumber: Int = 0
    dynamic var _trackTimeMillis: Int = 0
    
    dynamic var _artistId: Int = 0
    dynamic var _artistName: String = ""
    dynamic var _artistViewUrl: String = ""
    
    dynamic var _previewUrl: String = ""
    
    dynamic var _longPreviewUrl: String?
    let _longPreviewDuration: RealmOptional<Int> = RealmOptional()
    
    dynamic var _longPreviewFileUrl: String?
    
    dynamic var _country: String = ""
    dynamic var _currency: String = ""
    
    dynamic var _primaryGenreName: String = ""
    
    
    dynamic var _kind: String = ""
    
    dynamic var _wrapperType: String = ""
    
    dynamic var _releaseDate: String = ""
    
    dynamic var _isStreamable: Bool = false
    
    dynamic var _createAt: NSDate = NSDate()
    
    dynamic var _collection: _Collection?
    
    dynamic var _artist: _Artist?
    
    let histories = LinkingObjects(fromType: _HistoryRecord.self, property: "_track")
    
    
    override class func primaryKey() -> String? { return "_trackId" }
}

extension _Track {
    
    var trackId: Int { return _trackId }
    
    var trackName: String { return _trackName }
    
    var trackViewURL: NSURL { return NSURL(string: _trackViewUrl)! }
    
    var collection: Collection { return _collection! }
    
    var artist: Artist { return _artist! }
    
    var cached: Bool {
        guard let path = _longPreviewFileUrl else { return false }
        return NSFileManager.defaultManager().fileExistsAtPath(path)
    }
    
    func artworkURL(size size: Int) -> NSURL {
        return collection.artworkURL(size: size)
    }
}

extension _Track: Decodable {
    
    static func decode(e: Extractor) throws -> Self {
        
        let obj = self.init()
        obj._trackId = try e.value("trackId")
        obj._trackName = try e.value("trackName")
        obj._trackCensoredName = try e.value("trackCensoredName")
        obj._trackViewUrl = try e.value("trackViewUrl")
        obj._trackPrice = try e.value("trackPrice")
        obj._trackExplicitness = try e.value("trackExplicitness")
        obj._trackCount = try e.value("trackCount")
        obj._trackNumber = try e.value("trackNumber")
        obj._trackTimeMillis = try e.value("trackTimeMillis")
        
        obj._artistId = try e.value("artistId")
        obj._artistName = try e.value("artistName")
        obj._artistViewUrl = try e.value("artistViewUrl")
        
        obj._previewUrl = try e.value("previewUrl")
        
        obj._country = try e.value("country")
        obj._currency = try e.value("currency")
        
        obj._primaryGenreName = try e.value("primaryGenreName")
        
        obj._kind = try e.value("kind")
        
        obj._wrapperType = try e.value("wrapperType")
        
        obj._releaseDate = try e.value("releaseDate")
        
        obj._isStreamable = try e.valueOptional("isStreamable") ?? false
        
        let collection: _Collection = try Himotoki.decodeValue(e.rawValue)
        obj._collection = collection
        
        let artist: _Artist = try Himotoki.decodeValue(e.rawValue)
        obj._artist = artist
        
        return obj
    }
}
