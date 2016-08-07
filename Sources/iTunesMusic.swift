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


private let _previewer = Preview()

public let player: Player = PlayerImpl(previewer: _previewer)

private let realmObjectTypes: [RealmSwift.Object.Type] = [
    _Media.self,
    _GenresCache.self,
    _Collection.self,
    _ChartUrls.self,
    _HistoryCache.self,
    _SearchCache.self,
    _SearchTrendsCache.self,
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
    _RssCache.self,
    _Review.self,
    _ReviewCache.self,
]

private let configuration: Realm.Configuration = {
    let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
    // swiftlint:disable force_try
    let fileURL = try! URL(fileURLWithPath: path).appendingPathComponent("itunes.realm")
    var config = Realm.Configuration(fileURL: fileURL)
    config.objectTypes = realmObjectTypes
    return config
}()

public struct LaunchOptions {

}

public func launch(with options: LaunchOptions? = nil) {

    player.install(middleware: Model.History.shared)
    player.install(middleware: Downloader(previewer: _previewer))
}

public func iTunesRealm() -> Realm {
    // swiftlint:disable force_try
    return try! Realm(configuration: configuration)
}
