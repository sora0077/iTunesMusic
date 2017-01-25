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

    func value(preview: String, duration: Int) -> (URL, Int)? {
        guard let url = URL(string: preview) else { return nil }
        return (url, duration)
    }

    func decode() -> (URL, Int)? {
        guard let offers = item["store-offers"] as? [String: AnyObject] else {
            return nil
        }
        if let plus = offers["PLUS"] {
            if let p = plus["preview-url"] as? String,
                let d = plus["preview-duration"] as? Int {
                return value(preview: p, duration: d)
            }
        } else if let hqpre = offers["HQPRE"] {
            if let p = hqpre["preview-url"] as? String,
                let d = hqpre["preview-duration"] as? Int {
                return value(preview: p, duration: d)
            }
        }
        return nil
    }

    guard let ret = decode() else {
        throw iTunesMusicAPIError.notFound
    }
    return ret
}
