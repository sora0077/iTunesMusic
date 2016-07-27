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

    private enum WrapperType: String {
        case track, collection, artist
    }

    enum Wrapper {
        case track(_Track)
        case collection(_Collection)
        case artist(_Artist)
    }

    let objects: [Wrapper]
}

extension LookupResponse: Decodable {

    static func decode(_ e: Extractor) throws -> LookupResponse {
        let results = e.rawValue["results"] as! [[String: AnyObject]]
        var items: [Wrapper] = []
        for item in results {
            guard let wrapperType = WrapperType(rawValue: item["wrapperType"] as? String ?? "") else { continue }
            switch wrapperType {
            case .track:
                items.append(Wrapper.track(try Himotoki.decodeValue(item)))
            case .collection:
                items.append(Wrapper.collection(try Himotoki.decodeValue(item)))
            case .artist:
                items.append(Wrapper.artist(try Himotoki.decodeValue(item)))
            }
        }
        return LookupResponse(objects: items)
    }
}

struct LookupWithIds<Results where Results: Decodable>: iTunesRequestType {

    typealias Response = Results

    let method = HTTPMethod.GET

    let baseURL = URL(string: "https://itunes.apple.com")!

    let path = "lookup"

    let ids: [Int]

    var lang = Locale.current.object(forKey: Locale.Key.identifier) as! String

    var country = Locale.current.object(forKey: Locale.Key.countryCode) as! String

    let limit = 500

    var queryParameters: [String : AnyObject]? {
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
