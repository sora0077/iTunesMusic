//
//  LookupWithIds.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/19.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki


struct LookupResultPage {
    
    var objects: [_Track] = []
}

extension LookupResultPage: Decodable {
    
    static func decode(e: Extractor) throws -> LookupResultPage {
        var obj = LookupResultPage()
        obj.objects = try e.array("results")
        return obj
    }
}


struct LookupWithIds<Results where Results: Decodable>: iTunesRequestType {
    
    typealias Response = Results
    
    let method = HTTPMethod.GET
    
    let baseURL = NSURL(string: "https://itunes.apple.com")!
    
    let path = "lookup"
    
    let ids: [Int]
    
    var lang = NSLocale.currentLocale().objectForKey(NSLocaleIdentifier) as! String
    
    var country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
    
    var queryParameters: [String : AnyObject]? {
        return [
            "id": ids.map(String.init).joinWithSeparator(","),
            "lang": lang,
            "country": country
        ]
    }
    
    func interceptURLRequest(URLRequest: NSMutableURLRequest) throws -> NSMutableURLRequest {
        print(URLRequest)
        return URLRequest
    }
}

extension LookupWithIds {
    
    init(ids: [Int]) {
        self.ids = ids
    }
    
    init(id: Int) {
        self.ids = [id]
    }
}