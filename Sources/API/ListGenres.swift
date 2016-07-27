//
//  ListGenres.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/20.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki


struct ListGenres<Response: Decodable>: iTunesRequestType {

    let method = HTTPMethod.GET

    let baseURL: URL = URL(string: "https://itunes.apple.com")!

    let path: String = "WebObjects/MZStoreServices.woa/ws/genres"

    var country = Locale.current.compatible.countryCode

    var queryParameters: [String : AnyObject]? {
        return [
            "id": 34,  // music
            "cc": country,
        ]
    }

    func response(from object: AnyObject, urlResponse: HTTPURLResponse) throws -> Response {
        let root = (object as! [String: AnyObject]).values.first as! [String: AnyObject]
        return try Response.decodeValue(root)
    }
}
