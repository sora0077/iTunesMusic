//
//  ObservableList.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift


//MARK: - ObservableList
public protocol ObservableList: class {

    var changes: Observable<CollectionChange> { get }
}

fileprivate struct ObservableListKey {

    static var changes: UInt8 = 0
}

extension ObservableList {

    public var changes: Observable<CollectionChange> {
        return associatedObject(self, &ObservableListKey.changes) {
            // swiftlint:disable force_cast
            asObservable((self as! _ObservableList)._changes)
        }
    }
}


//MARK: - _ObservableList
protocol _ObservableList: class {

    var _changes: PublishSubject<CollectionChange> { get }
}

fileprivate struct _ObservableListKey {
    static var _changes: UInt8 = 0
}

extension _ObservableList {

    var _changes: PublishSubject<CollectionChange> {
        return associatedObject(self, &_ObservableListKey._changes) {
            PublishSubject<CollectionChange>()
        }
    }
}
