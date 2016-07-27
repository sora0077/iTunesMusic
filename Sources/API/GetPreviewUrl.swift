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

    typealias Response = (URL, Int)

    let id: Int

    let baseURL: URL

    var method: HTTPMethod { return .GET }

    var path: String { return "" }

    var headerFields: [String : String] {
        return [
            "X-Apple-Store-Front": "143462-9,4",
        ]
    }

    var dataParser: DataParserType {
        return PropertyListDataParser(options: [])
    }

    init(id: Int, url: URL) {
        self.id = id
        baseURL = url
    }

    func response(from object: AnyObject, urlResponse: HTTPURLResponse) throws -> Response {

        if let items = object["items"] as? [[String: AnyObject]] {
            for item in items {
                guard let id = item["item-id"] as? Int else { continue }
                if self.id == id {
                    return try getPreviewURL(item: item)
                }
            }
        }
        throw iTunesMusicError.notFound
    }
}


private func getPreviewURL(item: [String: AnyObject]) throws -> (URL, Int) {

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
        if let url = URL(string: preview) {
            return (url, duration)
        }
    }


    throw iTunesMusicError.notFound
}
