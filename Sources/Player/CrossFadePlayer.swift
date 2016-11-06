//
//  CrossFadePlayer.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import APIKit
import RxSwift
import ErrorEventHandler
import RealmSwift
import AbstractPlayerKit


private class PlayerItem: AbstractPlayerKit.PlayerItem {

}

private final class PlayerTrackItem: PlayerItem {

    private let track: Model.Track

    init(track: Model.Track) {
        self.track = track

        super.init()
    }

    override func fetcher() -> Observable<AVPlayerItem?> {
        guard let track = track.entity, track.canPreview else {
            return .just(nil)
        }

        func fetchPreviewURL() -> Observable<URL?> {
            let (id, viewURL) = (track.id, track.viewURL)
            return Observable<URL?>.create { subscriber in
                let task = Session.shared.send(GetPreviewUrl(id: id, url: viewURL), callbackQueue: callbackQueue) { [weak self] result in
                    switch result {
                    case .success(let (url, duration)):
                        let realm = iTunesRealm()
                        try? realm.write {
                            guard let track = self?.track.entity?.impl else { return }
                            let metadata = _TrackMetadata(track: track)
                            metadata.updatePreviewURL(url)
                            metadata.duration = Double(duration) / 1000
                            realm.add(metadata, update: true)
                        }
                        subscriber.onNext(url)
                    case .failure:
                        subscriber.onNext(nil)
                    }
                }
                task?.resume()
                return Disposables.create {
                    task?.cancel()
                }
            }
        }

        func getPreviewURL() -> Observable<URL?>? {
            guard let url = track.metadata?.fileURL ?? track.metadata?.previewURL else { return nil }
            return .just(url)
        }

        return (getPreviewURL() ?? fetchPreviewURL()).flatMap { url -> Observable<AVPlayerItem?> in
            guard let url = url else { return .just(nil) }
            return Observable.create { subscriber in
                let asset = AVURLAsset(url: url)
                asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    let item = AVPlayerItem(asset: asset)
                    subscriber.onNext(item)
                }
                return Disposables.create()
            }
        }
    }

    override func didFinishRequest() -> PlayerItem.RequestState {
        return .done
    }
}

private final class PlayerListItem: PlayerItem {

    private let playlist: Playlist

    private var items: [PlayerTrackItem] = []

    init(playlist: Playlist) {
        self.playlist = playlist

        super.init()
    }

    override func fetcher() -> Observable<AVPlayerItem?> {
        return Observable<Observable<AVPlayerItem?>>.create { [weak self] subscriber in
                DispatchQueue.main.async {
                    guard let `self` = self else { return }
                    let index = self.items.count
                    let playlist = self.playlist

                    if playlist.isTrackEmpty || playlist.trackCount <= index {
                        subscriber.onNext(.just(nil))
                        return
                    }
                    if let paginator = playlist as? _Fetchable,
                        !paginator._hasNoPaginatedContents && playlist.trackCount - index < 3 {
                        if !paginator._requesting.value {
                            paginator.fetch(ifError: DefaultError.self, level: DefaultErrorLevel.none) { error in
                                subscriber.onNext(.just(nil))
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                subscriber.onNext(.just(nil))
                            }
                        }
                        return
                    }
                    let track = Model.Track(track: playlist.track(at: index))
                    let item = PlayerTrackItem(track: track)
                    self.items.append(item)
                    subscriber.onNext(item.fetcher())
                }
                return Disposables.create()
            }.flatMap { $0 }
    }

    override func didFinishRequest() -> PlayerItem.RequestState {
        return DispatchQueue.main.sync {
            if self.playlist.isTrackEmpty {
                return .done
            }
            if self.playlist.trackCount == self.items.count {
                return .done
            }
            return .prepareForRequest
        }
    }
}

private enum DefaultError: ErrorLog.Error {
    case none

    init(error: Swift.Error?) {
        self = .none
    }
}

private enum DefaultErrorLevel: ErrorLog.Level {
    case none
}

final class Player2 {

    fileprivate let core: AbstractPlayerKit.Player

    var errorType: ErrorLog.Error.Type = DefaultError.self

    var errorLevel: ErrorLog.Level = DefaultErrorLevel.none

    var nowPlaying: Observable<Track?> {
        return Observable.just(nil)
    }

    var currentTime: Observable<Float64> {
        return Observable.just(1)
    }

    var playlingQueue: Observable<[Model.Track]> {
        return Observable.just([])
    }

    var playing: Bool = false

    private let queuePlayer = AVQueuePlayer()

    init() {
        core = AbstractPlayerKit.Player(queuePlayer: queuePlayer)

        #if (arch(i386) || arch(x86_64)) && os(iOS)
            queuePlayer.volume = 0.02
            print("simulator")
        #else
            print("iphone")
        #endif
    }

    func install(middleware: PlayerMiddleware) {

    }

    func play() {

    }

    func pause() {

    }

    func nextTrack() {

    }

    func add(track: Model.Track) {
        let item = PlayerTrackItem(track: track)
        core.insert(item)
    }

    func add(playlist: Playlist) {
        let item = PlayerListItem(playlist: playlist)
        core.insert(item, after: nil)
    }

    func removeAll() {

    }
}

extension Player2: Player {

}
