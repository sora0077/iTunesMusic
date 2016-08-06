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
