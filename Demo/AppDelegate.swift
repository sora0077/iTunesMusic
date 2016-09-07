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


extension UIAlertController {

    static func alertController(with event: ErrorLog.Event) -> UIAlertController {
        let alert = UIAlertController(
            title: (event.error as? AppError)?.title,
            message: (event.error as? AppError)?.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            event.resolved()
        }))

        return alert
    }
}

protocol AppError: ErrorLog.Error {
    var title: String { get }
    var message: String? { get }
}

extension AppError {

    var message: String? { return nil }
}

enum CommonError: AppError {
    case none, error(Swift.Error)

    init(error: Swift.Error?) {
        self = error.map(CommonError.error) ?? .none
    }

    var title: String {
        return "エラー"
    }

    #if DEBUG
    var message: String? {
        switch self {
        case .none:
            return "不明なエラー"
        case .error(let error):
            return "\(error)"
        }
    }
    #endif
}

enum AppErrorLevel: ErrorEventHandler.ErrorLevel {
    case slirent, alert
}

enum WindowLevel: Int, WindowKit.WindowLevel {
    case main
    case alert = 2

    static let mainWindowLevel: WindowLevel = .main
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private lazy var manager: Manager<WindowLevel> = Manager(mainWindow: self.window!)

    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        clearAllImageCaches()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            fatalError()
        }
        application.beginReceivingRemoteControlEvents()


        manager[.alert].rootViewController = UIViewController()

        ErrorLog.event
            .drive(onNext: { [weak self] error in
                print(error)
                switch error.level {
                case let level as AppErrorLevel:
                    switch level {
                    case .alert:
                        let alert = UIAlertController.alertController(with: error)
                        self?.manager[.alert].rootViewController?.present(alert, animated: true, completion: nil)
                    case .slirent:
                        break
                    }
                default:
                    break
                }
            })
            .addDisposableTo(disposeBag)

        print(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])

        launch(with: LaunchOptions(location: .group("group.jp.sora0077.itunesmusic")))

        player.install(middleware: ControlCenter())

        window?.tintColor = UIColor.lightGray

        print((iTunesRealm()).configuration.fileURL?.absoluteString ?? "")
        print((iTunesRealm()).schema.objectSchema.map { $0.className })

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
