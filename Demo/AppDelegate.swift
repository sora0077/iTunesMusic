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
import RxSwift
import RxCocoa
import RealmSwift
import MediaPlayer
import WindowKit
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


final class InnerShadowView: UIView {

    private var shadowLayer = CALayer()

    override func layoutSubviews() {
        super.layoutSubviews()

        makeShadow(to: self)
    }

    func makeShadow(to view: UIView) {
        let sublayer = CALayer()
        shadowLayer.removeFromSuperlayer()
        shadowLayer = sublayer

        sublayer.frame = view.bounds
        view.layer.addSublayer(sublayer)
        sublayer.masksToBounds = true

        let width: CGFloat = 20

        let size = sublayer.bounds.size
        var point = CGPoint(x: -width, y: -width)

        let path = CGMutablePath()
        path.move(to: point)
        point.x += size.width + width
        path.addLine(to: point)
        point.y += width
        path.addLine(to: point)
        point.x -= size.width
        path.addLine(to: point)
        point.y += size.height
        path.addLine(to: point)
        point.x -= width
        path.addLine(to: point)
        point.y -= size.height + width
        path.addLine(to: point)

        path.closeSubpath()

        sublayer.shadowOffset = CGSize(width: 10, height: 10)
        sublayer.shadowOpacity = 0.8
        sublayer.shadowRadius = 10
        sublayer.shadowPath = path
    }
}


final class PlayingViewController: UIViewController {

    private let artworkImageView = UIImageView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    private let shadowView = InnerShadowView()

    private var animator: UIViewPropertyAnimator!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(artworkImageView)
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.snp.makeConstraints { make in
            make.top.equalTo(-20)
            make.bottom.equalTo(20)
            make.left.right.equalTo(-20)
        }

        view.addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }

        view.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.reanimate),
            name: .UIApplicationDidBecomeActive,
            object: nil
        )

        let xAxis = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        let yAxis = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        xAxis.minimumRelativeValue = 20
        xAxis.maximumRelativeValue = -20
        yAxis.minimumRelativeValue = 40
        yAxis.maximumRelativeValue = -40
        let effect = UIMotionEffectGroup()
        effect.motionEffects = [xAxis, yAxis]
        artworkImageView.addMotionEffect(effect)
    }

    func setArtwork(of collection: iTunesMusic.Collection, size: CGFloat) {
        //animator.fractionComplete = 0.9
        artworkImageView.setArtwork(of: collection, size: size)
    }

    @objc
    private func reanimate() {

        blurView.effect = UIBlurEffect(style: .dark)
        animator = UIViewPropertyAnimator(duration: 2, curve: .linear)
        animator.addAnimations {
            self.blurView.effect = nil
        }
        animator.startAnimation()
        animator.pauseAnimation()
        animator.fractionComplete = 0.94
    }
}


private func delegate() -> AppDelegate {
    // swiftlint:disable force_cast
    return UIApplication.shared.delegate as! AppDelegate
}

func playingViewController() -> PlayingViewController {
    // swiftlint:disable force_cast
    return delegate().manager[.background].rootViewController as! PlayingViewController
}

func routingManageViewController() -> UIViewController {
    // swiftlint:disable force_cast
    return delegate().manager[.routing].rootViewController!
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

    private let wormhole = MMWormhole(applicationGroupIdentifier: appGroupIdentifier, optionalDirectory: "wormhole")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
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

        print(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])

        ErrorHandlingSettings.launch()
        RoutingSettings.launch()

        launch(with: LaunchOptions(location: .group(appGroupIdentifier)))
        player.install(middleware: ControlCenter())
        player.errorType = CommonError.self
        player.errorLevel = AppErrorLevel.alert

        window?.backgroundColor = .clear
        window?.tintColor = UIColor.lightGray

        manager[.background].backgroundColor = UIColor(hex: 0x3b393a)

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
