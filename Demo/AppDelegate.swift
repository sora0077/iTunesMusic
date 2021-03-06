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
import ErrorEventHandler
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
    // swiftlint:disable:next force_cast
    return UIApplication.shared.delegate as! AppDelegate
}

func playbackViewController() -> PlaybackViewController {
    // swiftlint:disable:next force_cast
    return delegate().manager[.background].rootViewController as! PlaybackViewController
}

func routingManageViewController() -> UIViewController {
    return delegate().manager[.routing].rootViewController!
}

func indicatorManageViewController() -> UIViewController {
    return delegate().manager[.indicator].rootViewController!
}

func errorManageViewController() -> UIViewController {
    return delegate().manager[.alert].rootViewController!
}

func router() -> Router {
    return delegate().router
}

enum RealmError: Swift.Error {
    case initializeError
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    fileprivate let router = Router()

    var window: UIWindow?

    fileprivate lazy var manager: Manager<WindowLevel> = Manager(mainWindow: self.window!)
}

extension AppDelegate {
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        print(CommandLine.arguments)
        print(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])

        setupWindow()

        ErrorHandlingSettings.launch()
        RoutingSettings.launch()

        setupiTunesMusic()
        setupPlayer()

        window?.backgroundColor = .clear
        window?.tintColor = .lightGray
        window?.makeKey()

        print((iTunesRealm()).configuration.fileURL?.absoluteString ?? "")
        print((iTunesRealm()).schema.objectSchema.map { $0.className })

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { granted, _ in
            if granted {
                application.registerForRemoteNotifications()
            }
        }

        return true
    }

    private func setupWindow() {
        UIViewController.swizzle_setNeedsStatusBarAppearanceUpdate()
        manager[.background].rootViewController = PlaybackViewController()
        manager[.routing].rootViewController = MainStatusBarStyleUpdaterViewController()
        manager[.indicator].rootViewController = MainStatusBarStyleUpdaterViewController()
        manager[.alert].rootViewController = MainStatusBarStyleViewController()
        manager[.background].backgroundColor = .hex(0x3b393a)
    }

    private func setupiTunesMusic() {
        let defaults = UserDefaults.standard
        let location = RealmLocation.group(appGroupIdentifier)
        if defaults.bool(forKey: "SettingsBundle::deleteRealm") {
            do {
                try deleteRealm(from: location)
                ErrorLog.enqueue(error: RealmError.initializeError, with: CommonError.self, level: AppErrorLevel.alert)
            } catch {}
        }
        do {
            defaults.set(true, forKey: "SettingsBundle::deleteRealm")
            defaults.synchronize()
            try migrateRealm(from: .default, to: location)
            defaults.set(false, forKey: "SettingsBundle::deleteRealm")
            defaults.synchronize()
        } catch {
            fatalError("\(error)")
        }
        launch(with: LaunchOptions(location: location))
    }

    private func setupPlayer() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            fatalError()
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()

        player.install(middleware: ControlCenter())
        //player.install(middleware: PlayingInfoNotification())
        player.errorType = CommonError.self
        player.errorLevel = AppErrorLevel.alert
    }
}

extension AppDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
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

// MARK: - status bar hack
private extension UIViewController {
    static var swizzle_setNeedsStatusBarAppearanceUpdate: () -> Void = {
        let original = class_getInstanceMethod(
            UIViewController.self, #selector(UIViewController.setNeedsStatusBarAppearanceUpdate))
        let replaced = class_getInstanceMethod(
            UIViewController.self, #selector(UIViewController.swizzled_setNeedsStatusBarAppearanceUpdate))
        method_exchangeImplementations(original!, replaced!)
        return {}
    }()

    @objc
    func swizzled_setNeedsStatusBarAppearanceUpdate() {
        if let vc = delegate().manager[.alert].rootViewController {
            vc.swizzled_setNeedsStatusBarAppearanceUpdate()
        } else {
            swizzled_setNeedsStatusBarAppearanceUpdate()
        }
    }
}

private final class MainStatusBarStyleViewController: UIViewController {
    private static func dig(_ vc: UIViewController) -> UIStatusBarStyle? {
        if vc.isBeingDismissed { return nil }
        if let vc = vc.presentedViewController {
            return dig(vc)
        }
        return vc.preferredStatusBarStyle
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return delegate().manager[.routing].rootViewController?.presentedViewController.flatMap(MainStatusBarStyleViewController.dig)
            ?? delegate().manager[.main].rootViewController.flatMap(MainStatusBarStyleViewController.dig)
            ?? .default
    }
}

private final class MainStatusBarStyleUpdaterViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setNeedsStatusBarAppearanceUpdate()
    }
}
