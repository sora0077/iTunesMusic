//
//  RssCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/25.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki


class _RssCache: _Cache {

    dynamic var _genreId: Int = 0

    dynamic var fetched: Int = 0

    fileprivate let items = List<_RssItem>()

    let tracks = List<_Track>()

    var ids: [Int] {
        return items.map { $0.id }
    }

    var done: Bool {
        return items.count == tracks.count
    }

    override class func primaryKey() -> String? { return "_genreId" }
}

class _RssItem: RealmSwift.Object, Decodable {

    dynamic var id: Int = 0

    static func decode(_ e: Extractor) throws -> Self {
        let imid: String = try e.value("im:id")
        guard let id = Int(imid) else {
            throw DecodeError.typeMismatch(expected: "Int", actual: imid, keyPath: "im:id")
        }
        let obj = self.init()
        obj.id = id
        return obj
    }
}

extension _RssCache: Decodable {

    static func decode(_ e: Extractor) throws -> Self {
        let feed: Feed = try e.value("feed")
        let items = feed.entities.map { $0.item }
        let obj = self.init()
        obj.items.append(objectsIn: items)
        return obj
    }
}

private struct Feed: Decodable {
    struct Entry: Decodable {
        
        let item: _RssItem

        static func decode(_ e: Extractor) throws -> Entry {
            return Entry(item: try e.value(["id", "attributes"]))
        }
    }

    let entities: [Entry]

    static func decode(_ e: Extractor) throws -> Feed {
        return Feed(entities: try e.arrayOptional("entry") ?? [])
    }
}
