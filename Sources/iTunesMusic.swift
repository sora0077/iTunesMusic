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

private let realmObjectTypes: [RealmSwift.Object.Type] = [
    _Media.self,
    _Collection.self,
    _ChartUrls.self,
    _Artist.self,
    _RssUrls.self,
    _MyPlaylist.self,
    _HistoryRecord.self,
    _Genre.self,
    _TrackMetadata.self,
    _Track.self,
    _Review.self
]

private let configuration: Realm.Configuration = {
    var config = Realm.Configuration()
    config.objectTypes = realmObjectTypes
    config.fileURL = launchOptions.location.url
    return config
}()

public enum RealmLocation {
    case `default`
    case group(String)

    var url: URL {
        switch self {
        case .default:
            let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            return URL(fileURLWithPath: path).appendingPathComponent("itunes.realm")
        case .group(let identifier):
            let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            return dir!.appendingPathComponent("itunes.realm")
        }
    }
}

public struct LaunchOptions {
    public var location: RealmLocation

    public init(location: RealmLocation = .default) {
        self.location = location
    }
}
private var launchOptions: LaunchOptions!

public func migrateRealm(from: RealmLocation, to: RealmLocation) throws {
    let (from, to) = (from.url, to.url)
    if from == to { return }

    let manager = FileManager.default
    if manager.fileExists(atPath: to.absoluteString) {
        return
    }
    if !manager.fileExists(atPath: from.absoluteString) {
        return
    }

    try manager.moveItem(at: from, to: to)
    try manager.removeItem(at: from)
}

public func deleteRealm(from: RealmLocation) throws {
    try FileManager.default.removeItem(at: from.url)
}

public func launch(with options: LaunchOptions = LaunchOptions()) {
    launchOptions = options
}

public func iTunesRealm() -> Realm {
    // swiftlint:disable force_try
    return try! Realm(configuration: configuration)
}

extension Realm {
    public func delete<Base: RealmCollection>(_ objects: RandomAccessSlice<Base>) where Base._Element: Object {
        delete(Array(objects))
    }
}
