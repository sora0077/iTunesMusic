//
//  SearchWithKeyword.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki


protocol SearchWithKeywordResponseType {
    
    var term: String { get set }
}

struct SearchResponse: SearchWithKeywordResponseType {
    
    private enum WrapperType: String {
        case track, collection, artist
    }
    
    enum Wrapper {
        case track(_Track)
        case collection(_Collection)
        case artist(_Artist)
    }
    
    var term: String = ""
    
    let objects: [Wrapper]
}

extension SearchResponse: Decodable {
    
    static func decode(e: Extractor) throws -> SearchResponse {
        let results = e.rawValue["results"] as! [[String: AnyObject]]
        var items: [Wrapper] = []
        for item in results {
            guard let wrapperType = WrapperType(rawValue: item["wrapperType"] as? String ?? "") else { continue }
            switch wrapperType {
            case .track:
                items.append(Wrapper.track(try Himotoki.decodeValue(item)))
            case .collection:
                items.append(Wrapper.collection(try Himotoki.decodeValue(item)))
            case .artist:
                items.append(Wrapper.artist(try Himotoki.decodeValue(item)))
            }
        }
        return SearchResponse(term: "", objects: items)
    }
}


struct SearchWithKeyword<Results: SearchWithKeywordResponseType where Results: Decodable>: iTunesRequestType {
    
    typealias Response = Results
    
    let method = HTTPMethod.GET
    
    let baseURL = NSURL(string: "https://itunes.apple.com")!
    
    let path = "search"
    
    var term: String
    
    var media = "music"
    
    var entity = "song"
    
    var lang = NSLocale.currentLocale().objectForKey(NSLocaleIdentifier) as! String
    
    var country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
    
    var offset: Int
    
    var limit: Int = 50
    
    var queryParameters: [String : AnyObject]? {
        return [
            "term": term,
            "media": media,
            "entity": entity,
            "lang": lang,
            "country": country,
            "offset": offset,
            "limit": limit
        ]
    }
    
    func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
        
        var obj: Response = try decodeValue(object)
        obj.term = term
        return obj
    }
}

extension SearchWithKeyword {
    
    init(term: String, offset: Int = 0) {
        self.term = term
        self.offset = offset
    }
}
