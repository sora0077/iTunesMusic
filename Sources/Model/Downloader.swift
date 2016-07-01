
//
//  Downloader.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/01.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift


public final class Downloader {
    
    private let disposeBag = DisposeBag()
    
    public static let instance = Downloader()
    
    private init() {}
}

extension Downloader: PlayerMiddleware {
    
    public func didEndPlayTrack(trackId: Int) {
        let realm = try! Realm()
        if let track = realm.objectForPrimaryKey(_Track.self, key: trackId) {
            if track.histories.count > 2 {
                let preview = Preview.instance.queueing(track: track)
                if preview.fileURL != nil {
                    return
                }
                print("will cache in disk", track.trackName)
                preview.download()
                    .subscribeNext { url, _ in
                        print("cache ", url)
                    }
                    .addDisposableTo(disposeBag)
            }
        }
    }
}
