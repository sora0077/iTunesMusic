//
//  Routing.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import Routing
import iTunesMusic
import RxSwift

private struct Logger: Middleware {
    fileprivate func handle(request: Routing.Request, response: Response, next: @escaping (Response) -> Void) throws {
        print(request)
        let date = Date()
        var response = response
        response.closing {
            print("time: ", Date().timeIntervalSince(date))
        }
        next(response)
    }
}

final class RoutingSettings {
    static func launch() {
        router().install(middleware: Logger())
        router().register(pattern: "/track/:trackId([0-9]+)", handlers: playTrack)
        router().register(pattern: "/search", queue: .main, handlers: openSearchViewController)
        router().register(pattern: "/history", queue: .main, handlers: openHistoryViewController)
    }
}

private extension RoutingSettings {

    static let disposeBag = DisposeBag()

    static func playTrack(request: Request, response: Response, next: @escaping (Response) -> Void) {
        if let trackId = Int(request.parameters["trackId"] ?? "") {
            player.add(track: Model.Track(trackId: trackId))
        }
        next(response)
    }

    static func openSearchViewController(request: Request, response: Response, next: @escaping (Response) -> Void) {
        var request = request
        if let query = request.queryItems["q"] ?? "" {
            let root = routingManageViewController()

            func open() {
                let vc = SearchViewController(query: query)
                let nav = UINavigationController(rootViewController: vc)
                let item = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
                item.rx.tap.asDriver()
                    .drive(onNext: { [weak wnav=nav] _ in
                        wnav?.dismiss(animated: true, completion: nil)
                        })
                    .addDisposableTo(self.disposeBag)
                vc.navigationItem.rightBarButtonItem = item
                root.present(nav, animated: true) {
                    next(response)
                }
            }

            if let presented = root.presentedViewController {
                presented.dismiss(animated: true, completion: open)
            } else {
                open()
            }
        } else {
            next(response)
        }
    }

    static func openHistoryViewController(request: Request, response: Response, next: @escaping (Response) -> Void) {
        let root = routingManageViewController()

        func open() {
            let vc = HistoryViewController()
            let nav = UINavigationController(rootViewController: vc)
            let item = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
            item.rx.tap.asDriver()
                .drive(onNext: { [weak wnav=nav] _ in
                    wnav?.dismiss(animated: true, completion: nil)
                    })
                .addDisposableTo(self.disposeBag)
            vc.navigationItem.rightBarButtonItem = item
            root.present(nav, animated: true) {
                next(response)
            }
        }

        if let presented = root.presentedViewController {
            presented.dismiss(animated: true, completion: open)
        } else {
            open()
        }
    }
}
