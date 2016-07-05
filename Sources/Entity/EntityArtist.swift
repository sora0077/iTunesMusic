//
//  Artist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/03.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


public protocol Artist {
    
}

final class _Artist: RealmSwift.Object, Artist {
    
    dynamic var _artistId: Int = 0
    dynamic var _artistName: String = ""
    dynamic var _artistLinkUrl: String = ""
    
    let _collections = LinkingObjects(fromType: _Collection.self, property: "_artist")

    override class func primaryKey() -> String? { return "_artistId" }
}

extension _Artist: Decodable {
    
    static func decode(e: Extractor) throws -> Self {
        
        let obj = self.init()
        
        obj._artistId = try e.value("artistId")
        obj._artistName = try e.value("artistName")
        obj._artistLinkUrl = try e.valueOptional("artistViewUrl") ?? e.value("artistLinkUrl")
        return obj
    }
    
    static func collectionArtist(e: Extractor) throws -> Self? {
        
        do {
            let obj = self.init()
            
            obj._artistId = try e.value("collectionArtistId")
            obj._artistName = try e.value("collectionArtistName")
            obj._artistLinkUrl = try e.value("collectionArtistViewUrl")
            return obj
        }
        catch DecodeError.MissingKeyPath {
            return nil
        }
    }
}
