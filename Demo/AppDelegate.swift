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
import SDWebImage


func rx_prefetchArtworkURLs<Playlist: PlaylistType where Playlist: CollectionType, Playlist.Generator.Element == Track>(size size: Int) -> AnyObserver<Playlist> {
    return AnyObserver { on in
        if case .Next(let playlist) = on {
            let urls = playlist.lazy.flatMap { $0.artworkURL(size: size) }
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                SDWebImagePrefetcher.sharedImagePrefetcher().prefetchURLs(urls)
            }
        }
    }
}


extension UIScrollView {
    
    func rx_reachedBottom(offsetRatio offsetRatio: CGFloat = 0) -> Observable<Bool> {
        return rx_contentOffset
            .map { [weak self] contentOffset in
                guard let scrollView = self else {
                    return false
                }
                
                let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
                let y = contentOffset.y + scrollView.contentInset.top
                let threshold = max(0.0, scrollView.contentSize.height - visibleHeight - visibleHeight * offsetRatio)
                return y > threshold
        }
    }
}


extension UITableView {
    
    func rx_itemUpdates(configure: ((index: Int) -> (row: Int, section: Int))? = nil) -> AnyObserver<CollectionChange> {
        return UIBindingObserver(UIElement: self) { tableView, changes in
            switch changes {
            case .initial:
                tableView.reloadData()
            case let .update(deletions: deletions, insertions: insertions, modifications: modifications):
                func indexPath(i: Int) -> NSIndexPath {
                    let (row, section) = configure?(index: i) ?? (i, 0)
                    return NSIndexPath(forRow: row, inSection: section)
                }
                tableView.performUpdates(
                    deletions: deletions.map(indexPath),
                    insertions: insertions.map(indexPath),
                    modifications: modifications.map(indexPath)
                )
            }
            }.asObserver()
    }
    
    func performUpdates(deletions deletions: [NSIndexPath], insertions: [NSIndexPath], modifications: [NSIndexPath]) {
        
        beginUpdates()
        deleteRowsAtIndexPaths(deletions, withRowAnimation: .Automatic)
        insertRowsAtIndexPaths(insertions, withRowAnimation: .Automatic)
        reloadRowsAtIndexPaths(modifications, withRowAnimation: .Automatic)
        endUpdates()
    }
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let disposeBag = DisposeBag()


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        SDWebImageManager.sharedManager().imageCache.clearDisk()
        SDWebImageManager.sharedManager().imageCache.clearMemory()
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayback)
        try! session.setActive(true)

        History.instance.groupby
            .flatMap { tracks in
                tracks.isEmpty ? Observable.empty() : Preview(track: tracks[0].0).download()
            }
            .subscribeNext { url, duration in
                print(url)
            }
            .addDisposableTo(disposeBag)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}
