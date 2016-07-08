
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


final class Downloader {
    
    private let disposeBag = DisposeBag()
    
    private var downloaded: Set<Int> = []
}

extension Downloader: PlayerMiddleware {
    
    func didEndPlayTrack(trackId: Int) {
        if downloaded.contains(trackId) { return }
        let realm = try! Realm()
        if let track = realm.objectForPrimaryKey(_Track.self, key: trackId) {
            if track.histories.count > 2 {
                let preview = Preview.instance.queueing(track: track)
                if preview.fileURL != nil {
                    downloaded.insert(trackId)
                    return
                }
                print("will cache in disk", track.trackName)
                preview.download()
                    .subscribeNext { [weak self] url, _ in
                        print("cache ", url)
                        self?.downloaded.insert(trackId)
                    }
                    .addDisposableTo(disposeBag)
            }
        }
    }
}
