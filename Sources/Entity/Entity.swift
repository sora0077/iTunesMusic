//
//  Entity.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/31.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

@objc
final class _Media: RealmSwift.Object {
    enum MediaType {
        case track(Track)
        case collection(Collection)
        case artist(Artist)
    }
    @objc fileprivate(set) dynamic var track: _Track?
    @objc fileprivate(set) dynamic var collection: _Collection?
    @objc fileprivate(set) dynamic var artist: _Artist?

    var type: MediaType {
        switch (track, collection, artist) {
        case (let track?, _, _): return .track(track)
        case (_, let collection?, _): return .collection(collection)
        case (_, _, let artist?): return .artist(artist)
        default:
            fatalError()
        }
    }

    static func track(_ track: _Track) -> Self {
        let media = self.init()
        media.track = track
        return media
    }

    static func collection(_ collection: _Collection) -> Self {
        let media = self.init()
        media.collection = collection
        return media
    }

    static func artist(_ artist: _Artist) -> Self {
        let media = self.init()
        media.artist = artist
        return media
    }
}
