//
//  Model.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import Timepiece

public struct Model {}

// MARK: - CollectionChange
public enum CollectionChange {
    case initial
    case update(deletions: [Int], insertions: [Int], modifications: [Int])

    init<T>(_ change: RealmCollectionChange<T>) {

        switch change {
        case .initial:
            self = .initial
        case let .update(_, deletions: deletions, insertions: insertions, modifications: modifications):
            self = .update(deletions: deletions, insertions: insertions, modifications: modifications)
        case let .error(error):
            fatalError("\(error)")
        }
    }
}

// MARK: - RequestState
public enum RequestState: Equatable {
    case none, requesting, error(Swift.Error), done

    public static func == (lhs: RequestState, rhs: RequestState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.requesting, .requesting):
            return true
        case (.error, .error):
            return true
        case (.done, .done):
            return true
        default:
            return false
        }
    }
}
