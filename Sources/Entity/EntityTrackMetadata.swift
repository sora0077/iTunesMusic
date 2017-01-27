//
//  EntityTrackMetadata.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

public protocol TrackMetadata {
    var duration: Double? { get }
    var fileURL: URL? { get }
    var previewURL: URL? { get }
}

final class _TrackMetadata: RealmSwift.Object, TrackMetadata {
    fileprivate dynamic var _trackId: Int = 0

    fileprivate dynamic var _track: _Track?

    fileprivate dynamic var _longPreviewUrl: String?

    fileprivate dynamic var _longPreviewFileUrl: String?

    fileprivate let _longPreviewDuration: RealmOptional<Double> = RealmOptional()

    dynamic var _createAt: Date = Date()

    override class func primaryKey() -> String? { return "_trackId" }

    init(track: _Track) {
        super.init()

        _trackId = track.id
        _track = track
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }

    required init() {
        super.init()
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }

}

extension _TrackMetadata {
    var previewURL: URL? {
        return _longPreviewUrl.flatMap(URL.init)
    }

    var fileURL: URL? {
        guard let filename = _longPreviewFileUrl else { return nil }
        let fileURL = Settings.Track.Cache.directory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }

    var duration: Double? {
        set {
            _longPreviewDuration.value = newValue
        }
        get {
            return _longPreviewDuration.value
        }
    }

    func updatePreviewURL(_ url: URL) {
        _longPreviewUrl = url.absoluteString
    }

    func updateCache(filename: String) {
        _longPreviewFileUrl = filename
    }
}
