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

    fileprivate var downloading: Set<Int> = []

    init(previewer: Preview, threshold: Int = 3) {
        self.previewer = previewer
        self.threshold = threshold
    }
}

extension Downloader: PlayerMiddleware {

    func didEndPlayTrack(_ trackId: Int) {
        let realm = iTunesRealm()
        guard let track = realm.object(ofType: _Track.self, forPrimaryKey: trackId) else {
            return
        }
        let cache = realm.object(ofType: _DiskCacheCounter.self, forPrimaryKey: trackId) ?? newCache(with: trackId)
        // swiftlint:disable force_try
        try! realm.write {
            cache.counter += 1
            realm.add(cache, update: true)
        }
        guard cache.counter >= threshold else { return }
        guard !downloading.contains(trackId) else { return }
        
        downloading.insert(trackId)
        previewer.queueing(track: track).download()
            .subscribe(onNext: { [weak self] _ in
                _ = self?.downloading.remove(trackId)
            })
            .addDisposableTo(disposeBag)
    }

    private func newCache(with trackId: Int) -> _DiskCacheCounter {
        let cache = _DiskCacheCounter()
        cache.trackId = trackId
        return cache
    }
}
