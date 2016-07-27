//
//  iTunesMusic.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki
import RxSwift
import RealmSwift


public let player: Player = PlayerImpl(previewer: Preview.shared)

private let configuration: Realm.Configuration = {
    let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
    let fileURL = NSURL(fileURLWithPath: path).appendingPathComponent("itunes.realm")
    var config = Realm.Configuration(fileURL: fileURL)
    config.objectTypes = [
        _GenresCache.self,
        _Collection.self,
        _ChartUrls.self,
        _HistoryCache.self,
        _SearchCache.self,
        _ArtistCache.self,
        _Artist.self,
        _RssUrls.self,
        _RssItem.self,
        _MyPlaylist.self,
        _MyPlaylistCache.self,
        _AlbumCache.self,
        _HistoryRecord.self,
        _Genre.self,
        _TrackMetadata.self,
        _Track.self,
        _RssCache.self
    ]
    return config
}()


public func launch() {

    player.install(middleware: Model.History.shared)
    player.install(middleware: Downloader())
}

public func iTunesRealm() throws -> Realm {
    return try Realm(configuration: configuration)
}
