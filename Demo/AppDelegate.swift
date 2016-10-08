//
//  AppDelegate.swift
//  Demo
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import AVFoundation
import iTunesMusic
import APIKit
import RxSwift
import RxCocoa
import RealmSwift
import MediaPlayer
import WindowKit
import ErrorEventHandler
import VYPlayIndicatorSwift
import MMWormhole
import Routing


enum WindowLevel: Int, WindowKit.WindowLevel {
    case background = -1
    case main
    case routing
    case alert = 10

    static let mainWindowLevel: WindowLevel = .main
}


let appGroupIdentifier = "group.jp.sora0077.itunesmusic"


final class PlayingViewController: UIViewController {

    private let artworkImageView = UIImageView()
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    private var animator: UIViewPropertyAnimator!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(artworkImageView)
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }

        view.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }

        animator = UIViewPropertyAnimator(duration: 2, curve: .linear)
        animator.addAnimations {
            self.blurView.effect = nil
        }
        animator.startAnimation()
        animator.pauseAnimation()
        animator.fractionComplete = 0.8
    }

    func setArtwork(of collection: iTunesMusic.Collection, size: CGFloat) {
        //animator.fractionComplete = 0.9
        artworkImageView.setArtwork(of: collection, size: size)
    }
}


func delegate() -> AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
}

func playingViewController() -> PlayingViewController {
    return delegate().manager[.background].rootViewController as! PlayingViewController
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let router = Router()

    var window: UIWindow?

    fileprivate lazy var manager: Manager<WindowLevel> = Manager(mainWindow: self.window!)

    private let disposeBag = DisposeBag()

    private let wormhole = MMWormhole(applicationGroupIdentifier: appGroupIdentifier, optionalDirectory: "wormhole")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        wormhole.listenForMessage(withIdentifier: "aaa") { (_) in
            print("listenForMessage aaa")
        }

        clearAllImageCaches()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            fatalError()
        }
        application.beginReceivingRemoteControlEvents()

        manager[.background].rootViewController = PlayingViewController()
        manager[.routing].rootViewController = UIViewController()
        manager[.alert].rootViewController = UIViewController()

        ErrorLog.event
            .drive(onNext: { [weak self] error in
                print(error)
                switch error.level {
                case let level as AppErrorLevel:
                    switch level {
                    case .alert:
                        let root = self?.manager[.alert].rootViewController
                        let presented = root?.presentedViewController ?? root
                        let alert = UIAlertController.alertController(with: error)
                        presented?.present(alert, animated: true, completion: nil)
                    case .slirent:
                        break
                    }
                default:
                    break
                }
            })
            .addDisposableTo(disposeBag)

        print(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])

        launch(with: LaunchOptions(location: .group(appGroupIdentifier)))
        player.install(middleware: ControlCenter())
        player.errorType = CommonError.self
        player.errorLevel = AppErrorLevel.alert

        window?.backgroundColor = .clear
        window?.tintColor = UIColor.lightGray

        manager[.background].backgroundColor = UIColor(hex: 0x3b393a)


        struct Logger: Middleware {
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

        router.install(middleware: Logger())
        router.register(pattern: "/track/:trackId([0-9]+)") { request, response, next in
            if let trackId = Int(request.parameters["trackId"] ?? "") {
                player.add(track: Model.Track(trackId: trackId))
            }
            next(response)
        }

        router.register(pattern: "/search", queue: .main) { [weak self] request, response, next in
            guard let `self` = self else { return }
            var request = request
            if let query = request.queryItems["q"] ?? "", !query.isEmpty {
                let root = self.manager[.routing].rootViewController

                func open() {
                    let vc = SearchViewController(query: query)
                    let nav = UINavigationController(rootViewController: vc)
                    let item = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
                    item.rx.tap.asDriver()
                        .drive(onNext: { [weak wnav=nav] _ in
                            wnav?.dismiss(animated: true, completion: nil)
                        })
                        .addDisposableTo(self.disposeBag)
                    nav.navigationItem.rightBarButtonItem = item
                    root?.present(nav, animated: true) {
                        next(response)
                    }
                }

                if let presented = root?.presentedViewController {
                    presented.dismiss(animated: true, completion: open)
                } else {
                    open()
                }
            } else {
                next(response)
            }
        }

//        Router.default.get(pattern: "/track/:trackId") { request, params, next in
//
//            next()
//        }

        print(UIWindowLevelNormal)
        print(UIWindowLevelAlert)

        print((iTunesRealm()).configuration.fileURL?.absoluteString ?? "")
        print((iTunesRealm()).schema.objectSchema.map { $0.className })

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {

        if router.canOpenURL(url: url) {
            router.open(url: url)
            return true
        }
        return false
    }
}
