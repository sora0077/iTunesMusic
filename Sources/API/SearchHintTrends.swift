//
//  SearchHintTrends.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki


struct SearchHintTrendsResponse {
    var name: String
    var trends: [String]
}

extension SearchHintTrendsResponse: Decodable {

    static func decode(_ e: Extractor) throws -> SearchHintTrendsResponse {
        let trends = (e.rawValue as! [String: AnyObject])["trendingSearches"]! as? [[String: String]] ?? []
        return try SearchHintTrendsResponse(
            name: e.value(["header", "label"]),
            trends: trends.map { $0["label"]! }
        )
    }
}

struct SearchHintTrends: iTunesRequestType {

    typealias Response = SearchHintTrendsResponse

    let method = HTTPMethod.GET

    let baseUrl = URL(string: "https://search.itunes.apple.com")!

    let path = "/WebObjects/MZSearchHints.woa/wa/trends"

    var headerFields: [String : String] {
        return [
            "X-Apple-Store-Front": appleStoreFront(locale: locale),
        ]
    }

    fileprivate let locale: Locale

    init(locale: Locale = Locale.current) {
        self.locale = locale
    }
}
