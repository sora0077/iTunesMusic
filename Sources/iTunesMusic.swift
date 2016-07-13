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


public let player: Player = PlayerImpl()

private let configuration: Realm.Configuration = {
    let path = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0]
    let fileURL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent("itunes.realm")
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
        MyPlaylist.self,
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
    
    player.install(middleware: Model.History.instance)
    player.install(middleware: Downloader())
}

public func iTunesRealm() throws -> Realm {
    return try Realm(configuration: configuration)
}