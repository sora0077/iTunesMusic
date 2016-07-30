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

    private let previewer: Preview

    private var downloaded: Set<Int> = []

    init(previewer: Preview) {
        self.previewer = previewer
    }
}

extension Downloader: PlayerMiddleware {

    func didEndPlayTrack(_ trackId: Int) {
        if downloaded.contains(trackId) { return }
        let previewer = self.previewer
        let realm = iTunesRealm()
        if let track = realm.object(ofType: _Track.self, forPrimaryKey: trackId) {
            if track.histories.count > 2 {
                let preview = previewer.queueing(track: track)
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
