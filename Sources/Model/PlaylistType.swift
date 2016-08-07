//
//  PlaylistType.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/17.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift


public protocol PlaylistType: class {

    var name: String { get }

    var tracksChanges: Observable<CollectionChange> { get }

    var trackCount: Int { get }
    var isTrackEmpty: Bool { get }

    func track(at index: Int) -> Track
}

extension PlaylistType where Self: ObservableList {

    public var tracksChanges: Observable<CollectionChange> { return changes }
}
