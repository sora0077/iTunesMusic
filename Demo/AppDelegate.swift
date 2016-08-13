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
import SDWebImage
import RealmSwift
import MediaPlayer


func rx_prefetchArtworkURLs<Playlist: PlaylistType where Playlist: Swift.Collection, Playlist.Iterator.Element == Track>(size: Int) -> AnyObserver<Playlist> {
    return AnyObserver { on in
        if case .next(let playlist) = on {
            let urls = playlist.flatMap { $0.artworkURL(size: size) }
            DispatchQueue.global(qos: .background).async {
                SDWebImagePrefetcher.shared().prefetchURLs(urls)
            }
        }
    }
}


extension UIScrollView {

    func rx_reachedBottom(offsetRatio: CGFloat = 0) -> Observable<Bool> {
        return rx_contentOffset
            .map { [weak self] contentOffset in
                guard let scrollView = self else { return false }

                let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
                let y = contentOffset.y + scrollView.contentInset.top
                let threshold = max(0.0, scrollView.contentSize.height - visibleHeight - visibleHeight * offsetRatio)
                return y > threshold
            }
    }
}


private var UITableView_isMoving: UInt8 = 0
extension UITableView {

    var isMoving: Bool {
        set {
            objc_setAssociatedObject(self, &UITableView_isMoving, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &UITableView_isMoving) as? Bool ?? false
        }
    }

    func rx_itemUpdates(_ configure: ((index: Int) -> (row: Int, section: Int))? = nil) -> AnyObserver<CollectionChange> {
        return UIBindingObserver(UIElement: self) { tableView, changes in
            switch changes {
            case .initial:
                tableView.reloadData()
            case let .update(deletions: deletions, insertions: insertions, modifications: modifications):
                func indexPath(_ i: Int) -> IndexPath {
                    let (row, section) = configure?(index: i) ?? (i, 0)
                    return IndexPath(row: row, section: section)
                }
                tableView.performUpdates(
                    deletions: deletions.map(indexPath),
                    insertions: insertions.map(indexPath),
                    modifications: modifications.map(indexPath)
                )
            }
        }.asObserver()
    }

    func performUpdates(deletions: [IndexPath], insertions: [IndexPath], modifications: [IndexPath]) {

        beginUpdates()
        if isMoving && deletions.count == insertions.count && modifications.isEmpty {
            isMoving = false
            reloadSections(IndexSet(0..<numberOfSections), with: .automatic)
        } else {
            if !deletions.isEmpty {
                deleteRows(at: deletions, with: .automatic)
            }
            if !insertions.isEmpty {
                insertRows(at: insertions, with: .top)
            }
            if !modifications.isEmpty {
                reloadRows(at: modifications, with: .automatic)
            }
        }
        endUpdates()
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        SDWebImageManager.shared().imageCache.clearDisk()
        SDWebImageManager.shared().imageCache.clearMemory()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
        } catch {
            fatalError()
        }
        application.beginReceivingRemoteControlEvents()

        print(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])

        launch()

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
