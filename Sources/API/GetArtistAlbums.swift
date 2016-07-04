//
//  GetArtistAlbums.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/03.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki


struct GetArtistAlbum<R: Decodable>: iTunesRequestType {
    
    typealias Response = R
    
    let baseURL: NSURL
    
    var method: HTTPMethod { return .GET }
    
    var path: String { return "" }
    
    var headerFields: [String : String] {
        return [
            "X-Apple-Store-Front": "143462-9,4",
        ]
    }
    
    var dataParser: DataParserType {
        return PropertyListDataParser(options: .Immutable)
    }
    
    init(url: NSURL) {
        baseURL = url
    }
}
