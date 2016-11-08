//
//  AppDelegate.swift
//  Demo
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import UserNotifications
import AVFoundation
import iTunesMusic
import RxSwift
import RxCocoa
import RealmSwift
import MediaPlayer
import WindowKit
import Routing


enum WindowLevel: Int, WindowKit.WindowLevel {
    case background = -1
    case main
    case routing
    case indicator
    case alert = 10

    static let mainWindowLevel: WindowLevel = .main
}

func appURL(path: String) -> URL {
    return URL(string: "itunesmusic://\(path)")!
}

let appGroupIdentifier = "group.jp.sora0077.itunesmusic"


private func delegate() -> AppDelegate {
    // swiftlint:disable force_cast
    return UIApplication.shared.delegate as! AppDelegate
}

func playbackViewController() -> PlaybackViewController {
    // swiftlint:disable force_cast
    return delegate().manager[.background].rootViewController as! PlaybackViewController
}

func routingManageViewController() -> UIViewController {
    // swiftlint:disable force_cast
    return delegate().manager[.routing].rootViewController!
}

func indicatorManageViewController() -> UIViewController {
    // swiftlint:disable force_cast
    return delegate().manager[.indicator].rootViewController!
}

func errorManageViewController() -> UIViewController {
    // swiftlint:disable force_cast
    return delegate().manager[.alert].rootViewController!
}

func router() -> Router {
    return delegate().router
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    fileprivate let router = Router()

    var window: UIWindow?

    fileprivate lazy var manager: Manager<WindowLevel> = Manager(mainWindow: self.window!)

    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            fatalError()
        }
        application.beginReceivingRemoteControlEvents()

        print(CommandLine.arguments)

        manager[.background].rootViewController = PlaybackViewController()
        manager[.routing].rootViewController = UIViewController()
        manager[.indicator].rootViewController = UIViewController()
        manager[.alert].rootViewController = UIViewController()

        print(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])

        ErrorHandlingSettings.launch()
        RoutingSettings.launch()

        let location = RealmLocation.group(appGroupIdentifier)
        do {
            try migrateRealm(from: .default, to: location)
        } catch {
            fatalError("\(error)")
        }
        launch(with: LaunchOptions(location: location))
        player.install(middleware: ControlCenter())
        //player.install(middleware: PlayingInfoNotification())
        player.errorType = CommonError.self
        player.errorLevel = AppErrorLevel.alert

        window?.backgroundColor = .clear
        window?.tintColor = .lightGray

        manager[.background].backgroundColor = .hex(0x3b393a)

        print((iTunesRealm()).configuration.fileURL?.absoluteString ?? "")
        print((iTunesRealm()).schema.objectSchema.map { $0.className })

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
            if granted {
                application.registerForRemoteNotifications()
            }
        }

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

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let options = PlayingInfoNotification.shouldHandle(notification) {
            completionHandler(options)
        } else {
            completionHandler([])
        }
    }
}
