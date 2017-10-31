//
//  Collection.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/02.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki
import Timepiece

private let releaseDateTransformer = Transformer<String, Date> { string in
    //  2016-06-29T07:00:00Z
    return string.dateFromFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")!
}

public protocol Collection {
    var id: Int { get }
    var name: String { get }
    var artist: Artist { get }
    var trackCount: Int { get }
    subscript (index: Int) -> Track { get }
    func artworkURL(size: Int) -> URL
}

extension Collection {
    var impl: _Collection {
        // swiftlint:disable:next force_cast
        return self as! _Collection
    }
}

final class _Collection: RealmSwift.Object, Collection {
    @objc dynamic var _collectionId: Int = 0
    @objc dynamic var _collectionName: String = ""
    @objc dynamic var _collectionCensoredName: String = ""
    @objc dynamic var _collectionViewUrl: String = ""
    let _collectionPrice = RealmOptional<Float>()
    @objc dynamic var _collectionExplicitness: String = ""

    @objc dynamic var _artworkUrl60: String = ""
    @objc dynamic var _artworkUrl100: String = ""

    @objc dynamic var _trackCount: Int = 0

    @objc dynamic var _country: String = ""
    @objc dynamic var _currency: String = ""

    @objc dynamic var _copyright: String?

    @objc dynamic var _releaseDate = Date()

    @objc dynamic var _artist: _Artist?

    private let _tracks = LinkingObjects(fromType: _Track.self, property: "_collection")

    private(set) lazy var sortedTracks: Results<_Track> = self._tracks.sorted(by: [
        SortDescriptor(keyPath: "_discNumber", ascending: true),
        SortDescriptor(keyPath: "_trackNumber", ascending: true)]
    )

    override class func primaryKey() -> String? { return "_collectionId" }
}

extension _Collection: Swift.Collection {
    var startIndex: Int { return sortedTracks.startIndex }
    var endIndex: Int { return sortedTracks.endIndex }
    subscript (index: Int) -> Track { return sortedTracks[index] }
    func index(after i: Int) -> Int {
        return sortedTracks.index(after: i)
    }
}

extension _Collection: Decodable {
    static func decode(_ e: Extractor) throws -> Self {
        let obj = self.init()
        obj._collectionId = try e.value("collectionId")
        obj._collectionName = try e.value("collectionName")
        obj._collectionCensoredName = try e.value("collectionCensoredName")
        obj._collectionViewUrl = try e.value("collectionViewUrl")
        obj._collectionPrice.value = try e.valueOptional("collectionPrice")
        obj._collectionExplicitness = try e.value("collectionExplicitness")

        obj._artworkUrl60 = try e.value("artworkUrl60")
        obj._artworkUrl100 = try e.value("artworkUrl100")

        obj._trackCount = try e.value("trackCount")

        obj._country = try e.value("country")
        obj._currency = try e.value("currency")

        obj._copyright = try e.valueOptional("copyright")

        obj._releaseDate = try releaseDateTransformer.apply(e.value("releaseDate"))

        let artist: _Artist = try _Artist.collectionArtist(e) ?? Himotoki.decodeValue(e.rawValue)
        obj._artist = artist
        return obj
    }
}

// swiftlint:disable:next force_try
private let artworkRegex = try! NSRegularExpression(pattern: "[1-9]00x[1-9]00", options: [])
private let artworkCached = NSCache<NSString, NSURL>()

extension _Collection {
    var id: Int { return _collectionId }
    var name: String { return _collectionName }
    var artist: Artist { return _artist! }
    var trackCount: Int { return _trackCount }
    func artworkURL(size: Int) -> URL {
        let base = _artworkUrl100
        let key = "\(base)_____\(size)" as NSString
        if let url = artworkCached.object(forKey: key) {
            return url as URL
        }

        let replaced = artworkRegex.stringByReplacingMatches(
            in: base,
            options: [],
            range: NSRange(location: 0, length: base.utf16.count),
            withTemplate: "\(size)x\(size)"
        )
        let url = URL(string: replaced)!
        artworkCached.setObject(url as NSURL, forKey: key)
        return url
    }
}
