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
import SWXMLHash


func appleStoreFront(locale: Locale = Locale.current) -> String {
    return "143462-9,4"
}

func iTunesUserAgent(version: String = UIDevice.current().systemVersion) -> String {
    return "iTunes-iPhone/\(version)"
}


protocol iTunesRequestType: RequestType {

}

extension iTunesRequestType {

    func intercept(urlRequest: URLRequest) throws -> URLRequest {
        print(self, urlRequest)
        return urlRequest
    }
}

extension iTunesRequestType where Response: Decodable {

    func response(from object: AnyObject, urlResponse: HTTPURLResponse) throws -> Response {
        do {
            return try decodeValue(object)
        } catch {
            print(object)
            throw error
        }
    }
}

public enum iTunesMusicError: ErrorProtocol {
    case notFound
}

class PropertyListDataParser: DataParserType {

    let contentType: String?

    let options: PropertyListSerialization.ReadOptions

    init(options: PropertyListSerialization.ReadOptions, contentType: String? = "application/x-apple-plist") {
        self.options = options
        self.contentType = contentType
    }

    func parseData(_ data: Data) throws -> AnyObject {
        return try PropertyListSerialization.propertyList(from: data, options: PropertyListSerialization.MutabilityOptions(), format: nil)
    }
}

class XMLDataParser: DataParserType {

    class Wrapper {
        let xml: XMLIndexer
        init(xml: XMLIndexer) {
            self.xml = xml
        }
    }

    var contentType: String? = "application/xml"

    func parseData(_ data: Data) throws -> AnyObject {
        return Wrapper(xml: SWXMLHash.parse(data))
    }
}
