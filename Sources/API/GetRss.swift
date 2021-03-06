//
//  GetRss.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki

struct GetRss<R: Decodable>: iTunesRequest {
    typealias Response = R

    let method = HTTPMethod.get
    let baseURL: URL
    let path: String
}

extension GetRss {

    init(url: URL, limit: Int=200) {
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        comps.path = ""
        baseURL = comps.url!

        var paths = url.path.components(separatedBy: "/")
        paths.insert("limit=\(limit)", at: paths.count - 1)
        path = paths.joined(separator: "/")
    }
}
