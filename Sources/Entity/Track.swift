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
    
    
    dynamic var _collectionId: Int = 0
    dynamic var _collectionName: String = ""
    dynamic var _collectionCensoredName: String = ""
    dynamic var _collectionViewUrl: String = ""
    let _collectionPrice = RealmOptional<Float>()
    dynamic var _collectionExplicitness: String = ""
    
    
    dynamic var _artistId: Int = 0
    dynamic var _artistName: String = ""
    dynamic var _artistViewUrl: String = ""
    
    dynamic var _previewUrl: String = ""
    dynamic var _artworkUrl30: String = ""
    dynamic var _artworkUrl60: String = ""
    dynamic var _artworkUrl100: String = ""
    
    dynamic var _longPreviewUrl: String?
    let _longPreviewDuration: RealmOptional<Int> = RealmOptional()
    
    dynamic var _discCount: Int = 0
    dynamic var _discNumber: Int = 0
    
    dynamic var _country: String = ""
    dynamic var _currency: String = ""
    
    dynamic var _primaryGenreName: String = ""
    
    
    dynamic var _kind: String = ""
    
    dynamic var _wrapperType: String = ""
    
    dynamic var _releaseDate: String = ""
    
    dynamic var _isStreamable: Bool = false
    
    dynamic var _createAt: NSDate = NSDate()
    
    
    override class func primaryKey() -> String? { return "_trackId" }
}

extension _Track {
    
    var trackId: Int { return _trackId }
    
    var trackName: String { return _trackName }
    
    var trackViewURL: NSURL { return NSURL(string: _trackViewUrl)! }
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
        
        obj._collectionId = try e.value("collectionId")
        obj._collectionName = try e.value("collectionName")
        obj._collectionCensoredName = try e.value("collectionCensoredName")
        obj._collectionViewUrl = try e.value("collectionViewUrl")
        obj._collectionPrice.value = try e.valueOptional("collectionPrice")
        obj._collectionExplicitness = try e.value("collectionExplicitness")
        
        obj._artistId = try e.value("artistId")
        obj._artistName = try e.value("artistName")
        obj._artistViewUrl = try e.value("artistViewUrl")
        
        obj._previewUrl = try e.value("previewUrl")
        obj._artworkUrl30 = try e.value("artworkUrl30")
        obj._artworkUrl60 = try e.value("artworkUrl60")
        obj._artworkUrl100 = try e.value("artworkUrl100")
        
        obj._discCount = try e.value("discCount")
        obj._discNumber = try e.value("discNumber")
        
        obj._country = try e.value("country")
        obj._currency = try e.value("currency")
        
        obj._primaryGenreName = try e.value("primaryGenreName")
        
        obj._kind = try e.value("kind")
        
        obj._wrapperType = try e.value("wrapperType")
        
        obj._releaseDate = try e.value("releaseDate")
        
        obj._isStreamable = try e.valueOptional("isStreamable") ?? false
        
        return obj
    }
}
