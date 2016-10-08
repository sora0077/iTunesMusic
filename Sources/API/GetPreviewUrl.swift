//
//  GetPreviewUrl.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/11.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit


struct GetPreviewUrl: iTunesRequest {

    typealias Response = (URL, Int)

    let id: Int

    let baseURL: URL

    private let locale: Locale

    let method = HTTPMethod.get

    let path = ""

    var headerFields: [String : String] {
        return [
            "X-Apple-Store-Front": appleStoreFront(locale: locale),
        ]
    }

    var dataParser: DataParser {
        return PropertyListDataParser(options: [])
    }

    init(id: Int, url: URL, locale: Locale = Locale.current) {
        self.id = id
        baseURL = url
        self.locale = locale
    }

    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {

        if let items = (object as? [String: AnyObject])?["items"] as? [[String: AnyObject]] {
            for item in items {
                guard let id = item["item-id"] as? Int, self.id == id else { continue }
                return try getPreviewURL(item: item)
            }
        }
        throw iTunesMusicAPIError.notFound
    }
}


fileprivate func getPreviewURL(item: [String: AnyObject]) throws -> (URL, Int) {

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

    throw iTunesMusicAPIError.notFound
}
