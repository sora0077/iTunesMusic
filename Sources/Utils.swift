//
//  Utils.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift


func tick() {
    dispatch_async(dispatch_get_main_queue()) {
        NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
    }
}


func asObservable<T: ObservableConvertibleType>(input: T) -> Observable<T.E> {
    return input.asObservable().observeOn(MainScheduler.instance).shareReplay(1)
}

func asReplayObservable<T: ObservableConvertibleType>(input: T) -> Observable<T.E> {
    return asObservable(input).shareReplay(1)
}

extension Variable: ObservableConvertibleType {}

extension Array {
    
    subscript (safe range: Range<Index>) -> ArraySlice<Element> {
        return self[min(range.startIndex, count)..<min(range.endIndex, count)]
    }
}
