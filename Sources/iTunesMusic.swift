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

private let realmObjectTypes: [RealmSwift.Object.Type] = [
    _Media.self,
    _GenresCache.self,
    _Collection.self,
    _ChartUrls.self,
    _HistoryCache.self,
    _DiskCacheCounter.self,
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
    var config = Realm.Configuration()
    config.objectTypes = realmObjectTypes
    switch launchOptions.location {
    case .default:
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        config.fileURL = URL(fileURLWithPath: path).appendingPathComponent("itunes.realm")
    case .group(let identifier):
        let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        config.fileURL = dir!.appendingPathComponent("itunes.realm")
    }
    return config
}()


public enum RealmLocation {
    case `default`
    case group(String)
}

public struct LaunchOptions {
    public var location: RealmLocation

    public init(location: RealmLocation = .default) {
        self.location = location
    }
}
private var launchOptions: LaunchOptions!

/// TODO:
public func migrateRealm(from: RealmLocation, to: RealmLocation) {

}

public func launch(with options: LaunchOptions = LaunchOptions()) {
    launchOptions = options
    player.install(middleware: Model.History.shared)
    player.install(middleware: Model.DiskCache.shared)
}

public func iTunesRealm() -> Realm {
    // swiftlint:disable force_try
    return try! Realm(configuration: configuration)
}
