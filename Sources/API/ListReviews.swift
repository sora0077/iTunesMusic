//
//  ListReviews.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/28.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki
import Fuzi


struct ListReviews<R: Decodable>: iTunesRequestType {

    typealias Response = [R]

    let method = HTTPMethod.GET

    let baseURL: URL = URL(string: "https://itunes.apple.com")!

    var path: String {
        return "\(country)/rss/customerreviews/page=\(page)/id=\(id)/sortby=\(sortby)/\(format)"
    }

    var dataParser: DataParserType {
        return XMLDataParser()
    }

    let id: Int

    var page: UInt = 0

    var country = Locale.current.compatible.countryCode

    var sortby = "mostrecent"

    var format = "xml"

    func intercept(object: AnyObject, urlResponse: HTTPURLResponse) throws -> AnyObject {

        // swiftlint:disable force_cast
        let doc = object as! HTMLDocument
        let entries = doc.xpath("//entry")

        guard entries.count > 1 else {
            return []
        }

        return entries[1..<entries.endIndex].map { entry in
            [
                "updated": entry.firstChild(tag: "updated")!.stringValue,
                "id": entry.firstChild(tag: "id")!.stringValue,
                "title": entry.firstChild(tag: "title")!.stringValue,
                "content": entry.firstChild(xpath: "content[@type='text']")!.stringValue,
                "rating": entry.firstChild(tag: "rating")!.stringValue,
                "voteSum": entry.firstChild(tag: "voteSum")!.stringValue,
                "voteCount": entry.firstChild(tag: "voteCount")!.stringValue,
                "auther": entry.firstChild(xpath: "author/name")!.stringValue
            ]
        }
    }

    func response(from object: AnyObject, urlResponse: HTTPURLResponse) throws -> Response {
        return try decodeArray(object)
    }
}

extension ListReviews {

    init(id: Int, page: UInt = 1) {
        assert(page != 0)
        self.id = id
        self.page = page
        country = "jp"
    }
}
