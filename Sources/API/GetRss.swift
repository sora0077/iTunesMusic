
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


struct GetRss<R: Decodable>: iTunesRequestType {
    
    typealias Response = R
    
    let method = HTTPMethod.GET
    
    let baseURL: NSURL
    
    let path: String
}

extension GetRss {
    
    init(url: NSURL, limit: Int=200) {
        let comps = NSURLComponents(URL: url, resolvingAgainstBaseURL: true)!
        comps.path = nil
        baseURL = comps.URL!
        
        var paths = url.path!.componentsSeparatedByString("/")
        paths.insert("limit=\(limit)", atIndex: paths.count - 1)
        path = paths.joinWithSeparator("/")
    }
}
