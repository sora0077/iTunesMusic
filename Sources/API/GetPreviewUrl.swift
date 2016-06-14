//
//  GetPreviewUrl.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/11.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit


struct GetPreviewUrl: iTunesRequestType {
    
    typealias Response = (NSURL, Int)
    
    let id: Int
    
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
    
    init(id: Int, url: NSURL) {
        self.id = id
        baseURL = url
    }
    
    func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
        
        let items = object["items"] as! [[String: AnyObject]]
        for item in items {
            let id = item["item-id"] as! Int
//            print(item)
            if self.id == id {
                let previewUrl = item["store-offers"]!["PLUS"]!!["preview-url"] as! String
                let duration = item["store-offers"]!["PLUS"]!!["preview-duration"] as! Int
                guard let url = NSURL(string: previewUrl) else { throw iTunesMusicError.NotFound }
                return (url, duration)
            }
        }
        throw iTunesMusicError.NotFound
    }
}
