//
//  Track.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/05.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki

public protocol Track {
    var id: Int { get }
    var name: String { get }
    var viewURL: URL { get }
    var collection: Collection { get }
    var artist: Artist { get }
    var canPreview: Bool { get }
    /// milli seconds
    var duration: Int { get }
    var metadata: TrackMetadata? { get }
    func artworkURL(size: Int) -> URL
}

extension Track {
    // swiftlint:disable:next force_cast
    var impl: _Track { return self as! _Track }
}

@objc
final class _Track: RealmSwift.Object, Track {
    @objc dynamic var _trackId: Int = 0
    @objc dynamic var _trackName: String = ""
    @objc dynamic var _trackCensoredName: String = ""
    @objc dynamic var _trackViewUrl: String = ""
    let _trackPrice = RealmOptional<Float>()
    @objc dynamic var _trackExplicitness: String = ""
    @objc dynamic var _trackCount: Int = 0
    @objc dynamic var _trackNumber: Int = 0
    @objc dynamic var _trackTimeMillis: Int = 0

    @objc dynamic var _discCount: Int = 0
    @objc dynamic var _discNumber: Int = 0

    @objc dynamic var _previewUrl: String?

    @objc dynamic var _country: String = ""
    @objc dynamic var _currency: String = ""

    @objc dynamic var _primaryGenreName: String = ""

    @objc dynamic var _kind: String = ""

    @objc dynamic var _wrapperType: String = ""

    @objc dynamic var _releaseDate: String = ""

    @objc dynamic var _isStreamable: Bool = false

    @objc dynamic var _createAt: Date = Date()

    @objc dynamic var _collection: _Collection?

    @objc dynamic var _artist: _Artist?

    private let _histories = LinkingObjects(fromType: _HistoryRecord.self, property: "_track")

    private(set) lazy var histories: Results<_HistoryRecord> = self._histories.sorted(byKeyPath: "createAt", ascending: false)

    fileprivate let _metadata = LinkingObjects(fromType: _TrackMetadata.self, property: "_track")

    @objc dynamic var _metadataUpdated: Int = 0

    override class func primaryKey() -> String? { return "_trackId" }

    override class func ignoredProperties() -> [String] { return ["histories"] }
}

extension _Track {
    var id: Int { return _trackId }
    var name: String { return _trackName }
    var viewURL: URL { return URL(string: _trackViewUrl)! }
    var collection: Collection { return _collection! }
    var artist: Artist { return _artist! }
    var canPreview: Bool { return _previewUrl != nil }
    var duration: Int { return _trackTimeMillis }
    var metadata: TrackMetadata? { return _metadata.first }
    func artworkURL(size: Int) -> URL { return collection.artworkURL(size: size) }
}

extension _Track: Decodable {
    static func decode(_ e: Extractor) throws -> Self {
        let obj = self.init()
        obj._trackId = try e.value("trackId")
        obj._trackName = try e.value("trackName")
        obj._trackCensoredName = try e.value("trackCensoredName")
        obj._trackViewUrl = try e.value("trackViewUrl")
        obj._trackPrice.value = try e.valueOptional("trackPrice")
        obj._trackExplicitness = try e.value("trackExplicitness")
        obj._trackCount = try e.value("trackCount")
        obj._trackNumber = try e.value("trackNumber")
        obj._trackTimeMillis = try e.value("trackTimeMillis")

        obj._discCount = try e.value("discCount")
        obj._discNumber = try e.value("discNumber")

        obj._previewUrl = try e.valueOptional("previewUrl")

        obj._country = try e.value("country")
        obj._currency = try e.value("currency")

        obj._primaryGenreName = try e.value("primaryGenreName")

        obj._kind = try e.value("kind")

        obj._wrapperType = try e.value("wrapperType")

        obj._releaseDate = try e.value("releaseDate")

        obj._isStreamable = try e.valueOptional("isStreamable") ?? false

        let collection: _Collection = try Himotoki.decodeValue(e.rawValue)
        obj._collection = collection

        let artist: _Artist = try Himotoki.decodeValue(e.rawValue)
        obj._artist = artist

        return obj
    }
}
