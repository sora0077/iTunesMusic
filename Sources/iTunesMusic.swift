//
//  iTunesMusic.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki
import RxSwift


protocol iTunesRequestType: RequestType {
    
}

extension iTunesRequestType {
    
    func interceptURLRequest(URLRequest: NSMutableURLRequest) throws -> NSMutableURLRequest {
        print(self, URLRequest)
        return URLRequest
    }
}

extension iTunesRequestType where Response: Decodable {
    
    func responseFromObject(object: AnyObject, URLResponse: NSHTTPURLResponse) throws -> Response {
        return try decodeValue(object)
    }
}

public enum iTunesMusicError: ErrorType {
    case NotFound
}

class PropertyListDataParser: DataParserType {
    
    let contentType: String?
    
    let options: NSPropertyListReadOptions
    
    init(options: NSPropertyListReadOptions, contentType: String? = "application/x-apple-plist") {
        self.options = options
        self.contentType = contentType
    }
    
    func parseData(data: NSData) throws -> AnyObject {
        return try NSPropertyListSerialization.propertyListWithData(data, options: .Immutable, format: nil)
    }
}

func tick() {
    dispatch_async(dispatch_get_main_queue()) {
        NSRunLoop.currentRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.1))
    }
}



func asObservable<T: ObservableConvertibleType>(input: T) -> Observable<T.E> {
    return input.asObservable().observeOn(MainScheduler.instance)
}

func asReplayObservable<T: ObservableConvertibleType>(input: T) -> Observable<T.E> {
    return asObservable(input).shareReplay(1)
}

extension Variable: ObservableConvertibleType {}



public protocol Fetchable {
    
    var requestState: Observable<RequestState> { get }
    
    func fetch()
    
    func refresh(force force: Bool)
}

protocol FetchableInternal: Fetchable {
    
    var _requestState: Variable<RequestState> { get }
    
    var needRefresh: Bool { get }
    
    var hasNoPaginatedContents: Bool { get }
    
    func request(refreshing refreshing: Bool)
}

extension Fetchable {
    
    public func fetch() {
        _request(refreshing: false)
    }
    
    public func refresh(force force: Bool) {
        let s = self as! FetchableInternal
        if force || s.needRefresh {
            _request(refreshing: true)
        }
    }
    
    private func _request(refreshing refreshing: Bool) {
        let s = self as! FetchableInternal
        if [.done, .requesting].contains(s._requestState.value) {
            return
        }
        
        s._requestState.value = .requesting
        
        s.request(refreshing: refreshing)
    }
}

extension FetchableInternal {
    
    var hasNoPaginatedContents: Bool {
        return [.done, .error].contains(_requestState.value)
    }
}

