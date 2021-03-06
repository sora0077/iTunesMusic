//
//  ObservableList.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - ObservableList
public protocol ObservableList {
    var changes: Observable<CollectionChange> { get }
}

private struct ObservableListKey {
    static var changes: UInt8 = 0
}

extension ObservableList {

    public var changes: Observable<CollectionChange> {
        // swiftlint:disable:next force_cast
        return associatedObject(self, &ObservableListKey.changes, initial: asObservable((self as! _ObservableList)._changes))
    }
}

// MARK: - _ObservableList
protocol _ObservableList {

    var _changes: PublishSubject<CollectionChange> { get }
}

private struct _ObservableListKey {
    static var _changes: UInt8 = 0
}

extension _ObservableList {

    var _changes: PublishSubject<CollectionChange> {
        return associatedObject(self, &_ObservableListKey._changes, initial: PublishSubject<CollectionChange>())
    }
}
