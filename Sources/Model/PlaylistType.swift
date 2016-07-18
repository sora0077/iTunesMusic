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
    
    var changes: Observable<CollectionChange> { get }
    
    var count: Int { get }
    var isEmpty: Bool { get }
    
    subscript (index: Int) -> Track { get }
}

protocol PlaylistTypeInternal: PlaylistType {
    
    associatedtype RealmElement: Object
    
    var objects: AnyRealmCollection<RealmElement> { get }
}
