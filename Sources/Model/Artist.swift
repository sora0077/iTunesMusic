//
//  Artist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/04.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import APIKit
import Himotoki

struct Response: Decodable {
    
    static func decode(e: Extractor) throws -> Response {
        let items = e.rawValue["items"] as! [[String: AnyObject]]
        for item in items {
            if let type = item["type"] as? String where type == "separator" {
                print(item["title"] as? String)
            }
        }
        return Response()
    }
}


public final class ArtistModel {
    
    private let url: NSURL
    
    public init(url: NSURL) {
        self.url = url
    }
    
    func request(refreshing refreshing: Bool) {
        
        fetchIds()
    }
    
    private func fetchIds() {
        let session = Session.sharedSession
        session.sendRequest(GetArtistAlbum<Response>(url: url)) { [weak self] result in
            
            guard let `self` = self else { return }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                print(result)
            }
        }
    }
}
