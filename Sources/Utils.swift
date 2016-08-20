//
//  Utils.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import APIKit


let callbackQueue = CallbackQueue.dispatchQueue(DispatchQueue.global(qos: .background))


func tick() {
    DispatchQueue.main.async {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
    }
}

public func doOnMainThread(execute block: @autoclosure(escaping) () -> Void) -> Bool {
    guard Thread.isMainThread else {
        DispatchQueue.main.async(execute: block)
        return false
    }
    return true
}

func asObservable<T: ObservableConvertibleType>(_ input: T) -> Observable<T.E> {
    return input.asObservable().observeOn(MainScheduler.instance).shareReplay(1)
}

func asReplayObservable<T: ObservableConvertibleType>(_ input: T) -> Observable<T.E> {
    return asObservable(input).shareReplay(1)
}

extension Variable: ObservableConvertibleType {}

extension Array {

    subscript (safe range: Range<Index>) -> ArraySlice<Element> {
        return self[Swift.min(range.lowerBound, count)..<Swift.min(range.upperBound, count)]
    }
}
