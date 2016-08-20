//
//  Entity.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/31.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


final class _Media: RealmSwift.Object {

    enum MediaType {
        case track(Track)
        case collection(Collection)
        case artist(Artist)
    }

    fileprivate(set) dynamic var track: _Track?

    fileprivate(set) dynamic var collection: _Collection?

    fileprivate(set) dynamic var artist: _Artist?

    var type: MediaType {
        if let obj = track {
            return .track(obj)
        }
        if let obj = collection {
            return .collection(obj)
        }
        if let obj = artist {
            return .artist(obj)
        }
        fatalError()
    }

    static func track(track: _Track) -> Self {
        let media = self.init()
        media.track = track
        return media
    }

    static func collection(collection: _Collection) -> Self {
        let media = self.init()
        media.collection = collection
        return media
    }

    static func artist(artist: _Artist) -> Self {
        let media = self.init()
        media.artist = artist
        return media
    }
}
