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
            guard let id = item["item-id"] as? Int else { continue }
            if self.id == id {
                return try getPreviewURL(item)
            }
        }
        throw iTunesMusicError.NotFound
    }
}


private func getPreviewURL(item: [String: AnyObject]) throws -> (NSURL, Int) {
    
    if let offers = item["store-offers"] as? [String: AnyObject] {
        let preview: String
        let duration: Int
        if offers["PLUS"] != nil {
            preview = offers["PLUS"]!["preview-url"] as! String
            duration = offers["PLUS"]!["preview-duration"] as! Int
        } else {
            preview = offers["HQPRE"]!["preview-url"] as! String
            duration = offers["HQPRE"]!["preview-duration"] as! Int
        }
        if let url = NSURL(string: preview) {
            return (url, duration)
        }
    }
    
    
    throw iTunesMusicError.NotFound
}
