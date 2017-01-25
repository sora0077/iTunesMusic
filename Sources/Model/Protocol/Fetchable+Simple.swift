//
//  Fetchable+Simple.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/21.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import ErrorEventHandler
import APIKit

protocol _FetchableSimple: _Fetchable {
    associatedtype Request: iTunesRequest

    func makeRequest(refreshing: Bool) -> Request?

    func doResponse(_ response: Request.Response, request: Request, refreshing: Bool) -> RequestState
}

extension _FetchableSimple {

    func request(refreshing: Bool, force: Bool, ifError errorType: ErrorLog.Error.Type, level: ErrorLog.Level, completion: @escaping (RequestState) -> Void) {
        guard let request = makeRequest(refreshing: refreshing) else {
            completion(.done)
            return
        }

        Session.shared.send(request, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                completion(requestState)
            }

            switch result {
            case .success(let response):
                requestState = self.doResponse(response, request: request, refreshing: refreshing)
            case .failure(let error):
                requestState = .error(error)
            }
        }
    }
}
