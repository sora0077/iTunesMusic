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

private struct ObservableListKey {

    static var changes: UInt8 = 0
}

extension ObservableList {

    public var changes: Observable<CollectionChange> {
        if let changes = objc_getAssociatedObject(self, &ObservableListKey.changes) as? Observable<CollectionChange> {
            return changes
        }
        // swiftlint:disable force_cast
        let changes = asObservable((self as! _ObservableList)._changes)
        objc_setAssociatedObject(self, &ObservableListKey.changes, changes, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return changes
    }
}


//MARK: - _ObservableList
protocol _ObservableList: class {

    var _changes: PublishSubject<CollectionChange> { get }
}

private struct _ObservableListKey {
    static var _changes: UInt8 = 0
}

extension _ObservableList {

    var _changes: PublishSubject<CollectionChange> {
        if let change = objc_getAssociatedObject(self, &_ObservableListKey._changes) as? PublishSubject<CollectionChange> {
            return change
        }
        let change = PublishSubject<CollectionChange>()
        objc_setAssociatedObject(self, &_ObservableListKey._changes, change, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return change
    }

}
