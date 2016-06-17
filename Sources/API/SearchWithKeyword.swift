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

struct SearchResultPage: SearchWithKeywordResponseType {
    
    var term: String = ""
    
    var objects: [_Track] = []
}

extension SearchResultPage: Decodable {
    
    static func decode(e: Extractor) throws -> SearchResultPage {
        
        var obj = SearchResultPage()
        
        obj.objects = try e.array("results")
        
        return obj
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
    
    var limit: Int = 5
    
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
    
    func interceptURLRequest(URLRequest: NSMutableURLRequest) throws -> NSMutableURLRequest {
        print(URLRequest)
        return URLRequest
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
