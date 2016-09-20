//
//  Router.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/09/13.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation


protocol RouterMiddleware {

}


final class Router {

    public typealias Request = (URL, [String: String], () -> Void)
    public typealias Handler = (Request) -> Void


    struct Element {
        let pattern: String
        let handler: Handler
    }

    static let `default` = Router(scheme: "itunesmusic")

    private let _scheme: String

    private var middlewares: [RouterMiddleware] = []

    private var elements: [Element] = []

    init(scheme: String) {
        _scheme = scheme
    }

    func install(middleware: RouterMiddleware) {
        middlewares.append(middleware)
    }

    func get(pattern: String, handler: @escaping Handler) {
        elements.append(Element(pattern: pattern, handler: handler))
    }

    func canOpenURL(_ url: URL) -> Bool {

        return false
    }

    func open(_ url: URL) {

    }
    
    private func handle(_ url: URL) throws {
        
    }
}
