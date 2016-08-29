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


struct LookupResponse {

    fileprivate enum WrapperType: String {
        case track, collection, artist
    }

    enum Wrapper {
        case track(_Track)
        case collection(_Collection)
        case artist(_Artist)
        case unknown
    }

    let objects: [Wrapper]
}

extension LookupResponse.Wrapper: Decodable {

    static func decode(_ e: Extractor) throws -> LookupResponse.Wrapper {
        guard let wrapperType = LookupResponse.WrapperType(rawValue: try e.valueOptional("wrapperType") ?? "") else {
            return .unknown
        }
        switch wrapperType {
        case .track:
            return .track(try Himotoki.decodeValue(e.rawValue))
        case .collection:
            return .collection(try Himotoki.decodeValue(e.rawValue))
        case .artist:
            return .artist(try Himotoki.decodeValue(e.rawValue))
        }
    }
}

extension LookupResponse: Decodable {

    static func decode(_ e: Extractor) throws -> LookupResponse {
        return LookupResponse(objects: try e.array("results"))
    }
}

struct LookupWithIds<Results: Decodable>: iTunesRequestType {

    typealias Response = Results

    let method = HTTPMethod.get

    let baseUrl = URL(string: "https://itunes.apple.com")!

    let path = "lookup"

    let ids: [Int]

    var lang = Locale.current.identifier

    var country = Locale.current.regionCode!

    let limit = 500

    var queryParameters: [String : Any]? {
        return [
            "id": ids.map(String.init).joined(separator: ","),
            "entity": "song",
            "limit": limit,
            "lang": lang,
            "country": country
        ]
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
