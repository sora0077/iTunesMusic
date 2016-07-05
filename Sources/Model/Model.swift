//
//  Model.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift

public struct Model {
    
}


public enum CollectionChange {
    case initial
    case update(deletions: [Int], insertions: [Int], modifications: [Int])
    
    init<T>(_ change: RealmCollectionChange<T>) {
        
        switch change {
        case .Initial:
            self = .initial
        case let .Update(_, deletions: deletions, insertions: insertions, modifications: modifications):
            self = .update(deletions: deletions, insertions: insertions, modifications: modifications)
        case let .Error(error):
            fatalError("\(error)")
        }
    }
}
