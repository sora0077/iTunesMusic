//
//  EntityReview.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/27.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


public protocol Review {

    var auther: String { get }

    var title: String { get }

    var content: String { get }

    var rating: Int { get }
}


final class _Review: RealmSwift.Object, Review {

    private(set) dynamic var id = 0

    private(set) dynamic var auther = ""

    private(set) dynamic var title = ""

    private(set) dynamic var content = ""

    private(set) dynamic var rating = 0

    private(set) dynamic var voteCount = 0

    private(set) dynamic var voteSum = 0

    private(set) dynamic var postedAt = Date.distantPast
}
