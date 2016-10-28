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


struct ListReviews<R: Decodable>: iTunesRequest {

    typealias Response = [R]

    let method = HTTPMethod.get

    let baseURL: URL = URL(string: "https://itunes.apple.com")!

    var path: String {
        return "\(country)/rss/customerreviews/page=\(page)/id=\(id)/sortby=\(sortby)/\(format)"
    }

    var dataParser: DataParser {
        return XMLDataParser()
    }

    let id: Int

    var page: UInt = 0

    var country = Locale.current.regionCode

    var sortby = "mostrecent"

    var format = "xml"

    func intercept(object: Any, urlResponse: HTTPURLResponse) throws -> Any {

        // swiftlint:disable force_cast
        let doc = (object as! XMLDataParser.Wrapper).xml
        let entries = doc["feed"]["entry"].all

        guard entries.count > 1 else {
            return []
        }
        return try entries[1..<entries.endIndex].map { entry in
            return [
                "updated": entry["updated"].element!.text!,
                "id": entry["id"].element!.text!,
                "title": entry["title"].element!.text!,
                "content": try entry["content"].withAttr("type", "text").element?.text ?? "",
                "rating": entry["im:rating"].element!.text!,
                "voteSum": entry["im:voteSum"].element!.text!,
                "voteCount": entry["im:voteCount"].element!.text!,
                "auther": entry["author"]["name"].element!.text!,
            ]
        }
    }

    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
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
