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
import SWXMLHash
import iOS9to10


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
        let doc = (object as! XMLDataParser.Wrapper).xml
        let entries = doc["feed"]["entry"].all

        guard entries.count > 1 else {
            return []
        }
        return entries[1..<entries.endIndex].map { entry in
            [
                "updated": entry["updated"].element!.text!,
                "id": entry["id"].element!.text!,
                "title": entry["title"].element!.text!,
                "content": try! entry["content"].withAttr("type", "text").element!.text!,
                "rating": entry["im:rating"].element!.text!,
                "voteSum": entry["im:voteSum"].element!.text!,
                "voteCount": entry["im:voteCount"].element!.text!,
                "auther": entry["author"]["name"].element!.text!,
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
    }
}
