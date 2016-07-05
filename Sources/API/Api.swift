//
//  Api.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/06.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki

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
        do {
            return try decodeValue(object)
        } catch {
            print(object)
            throw error
        }
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
