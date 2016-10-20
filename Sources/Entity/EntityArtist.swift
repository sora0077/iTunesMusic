//
//  Artist.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/03.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


public protocol Artist {

    var id: Int { get }

    var name: String { get }
}

final class _Artist: RealmSwift.Object, Artist {

    dynamic var _artistId: Int = 0
    dynamic var _artistName: String = ""
    dynamic var _artistLinkUrl: String?

    private let _collections = LinkingObjects(fromType: _Collection.self, property: "_artist")

    private(set) lazy var sortedCollections: Results<_Collection> = self._collections.sorted(byProperty: "_collectionId", ascending: false)

    override class func primaryKey() -> String? { return "_artistId" }
}

extension _Artist {

    var id: Int { return _artistId }

    var name: String { return _artistName }
}

extension _Artist: Decodable {

    static func decode(_ e: Extractor) throws -> Self {

        let obj = self.init()

        obj._artistId = try e.value("artistId")
        obj._artistName = try e.value("artistName")
        obj._artistLinkUrl = try e.valueOptional("artistViewUrl") ?? e.valueOptional("artistLinkUrl")
        return obj
    }

    static func collectionArtist(_ e: Extractor) throws -> Self? {

        do {
            let obj = self.init()

            obj._artistId = try e.value("collectionArtistId")
            obj._artistName = try e.value("collectionArtistName")
            obj._artistLinkUrl = try e.valueOptional("collectionArtistViewUrl")
            return obj
        } catch DecodeError.missingKeyPath {
            return nil
        }
    }
}
