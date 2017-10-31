//
//  EntityReview.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/27.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import Himotoki

public protocol Review {
    var auther: String { get }
    var title: String { get }
    var content: String { get }
    var rating: Int { get }
}

extension Review {
    var impl: _Review {
        // swiftlint:disable:next force_cast
        return self as! _Review
    }
}

final class _Review: RealmSwift.Object, Review {
    fileprivate(set) dynamic var id = 0
    fileprivate(set) dynamic var auther = ""
    fileprivate(set) dynamic var title = ""
    fileprivate(set) dynamic var content = ""
    fileprivate(set) dynamic var rating = 0
    fileprivate(set) dynamic var voteCount = 0
    fileprivate(set) dynamic var voteSum = 0
    fileprivate(set) dynamic var postedAt = Date.distantPast
    override class func primaryKey() -> String? { return "id" }
}

private let intTransformer = Transformer<String, Int> {
    guard let val = Int($0) else {
        throw DecodeError.typeMismatch(expected: "Int", actual: "String", keyPath: "")
    }
    return val
}

private let postedAtTransformer = Transformer<String, Date> { string in
    //  2016-06-29T07:00:00-07:00
    return string.dateFromFormat("yyyy-MM-dd'T'HH:mm:sszzzz")!
}

extension _Review: Decodable {
    static func decode(_ e: Extractor) throws -> Self {
        let obj = self.init()
        obj.id = try intTransformer.apply(e.value("id"))
        obj.auther = try e.value("auther")
        obj.title = try e.value("title")
        obj.content = try e.value("content")
        obj.rating = try intTransformer.apply(e.value("rating"))
        obj.voteCount = try intTransformer.apply(e.value("voteCount"))
        obj.voteSum = try intTransformer.apply(e.value("voteSum"))
        obj.postedAt = try postedAtTransformer.apply(e.value("updated"))
        return obj
    }
}
