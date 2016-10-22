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

    fileprivate let disposeBag = DisposeBag()

    fileprivate let previewer: Preview
    fileprivate let threshold: Int

    fileprivate var downloaded: Set<Int> = []

    init(previewer: Preview, threshold: Int = 2) {
        self.previewer = previewer
        self.threshold = threshold
    }
}

extension Downloader: PlayerMiddleware {

    func didEndPlayTrack(_ trackId: Int) {
        if downloaded.contains(trackId) { return }
        let realm = iTunesRealm()
        guard let track = realm.object(ofType: _Track.self, forPrimaryKey: trackId), track.histories.count > threshold else {
            return
        }
        print("will cache in disk", track.name)
        previewer.queueing(track: track).download()
            .subscribe(onNext: { [weak self] url, _ in
                print("cache ", url)
                self?.downloaded.insert(trackId)
            })
            .addDisposableTo(disposeBag)
    }
}
