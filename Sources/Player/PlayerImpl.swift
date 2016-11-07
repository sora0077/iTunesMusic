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


private extension AVPlayerItem {

    private struct AVPlayerItemKey {
        static var trackId: UInt8 = 0
    }

    var trackId: Int? {
        get {
            return objc_getAssociatedObject(self, &AVPlayerItemKey.trackId) as? Int
        }
        set {
            objc_setAssociatedObject(self, &AVPlayerItemKey.trackId, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


private extension Notification.Name {
    static let PlayerTrackItemPrepareForPlay = Notification.Name("PlayerTrackItemPrepareForPlay")
}

public final class PlayerTrackItem: PlayerItem {

    fileprivate let track: Model.Track

    override public var name: String? { return track.entity?.name }

    init(track: Model.Track) {
        self.track = track

        super.init()
    }

    override public func fetcher() -> Observable<AVPlayerItem?> {
        guard let track = track.entity, track.canPreview else {
            return .just(nil)
        }

        func getPreviewURL() -> Observable<URL?>? {
            guard let url = track.metadata?.fileURL ?? track.metadata?.previewURL else { return nil }
            print(url)
            return .just(url)
        }

        let id = track.id
        return (getPreviewURL() ?? fetchPreviewURL(from: track)).flatMap { url -> Observable<AVPlayerItem?> in
            guard let url = url else { return .just(nil) }
            return Observable.create { subscriber in
                let asset = AVURLAsset(url: url)
                asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: "duration", error: &error)
                    switch status {
                    case .loaded:
                        let item = AVPlayerItem(asset: asset)
                        item.trackId = id
                        configureFading(item: item)
                        NotificationCenter.default.post(
                            name: .PlayerTrackItemPrepareForPlay,
                            object: item)
                        subscriber.onNext(item)
                    default:
                        subscriber.onNext(nil)
                    }
                }
                return Disposables.create()
            }
        }
    }

    private func fetchPreviewURL(from track: Track) -> Observable<URL?> {
        let (id, viewURL) = (track.id, track.viewURL)
        return Observable<URL?>.create { subscriber in
            let task = Session.shared.send(GetPreviewUrl(id: id, url: viewURL), callbackQueue: callbackQueue) { [weak self] result in
                switch result {
                case .success(let (url, duration)):
                    var fileURL: URL?
                    let realm = iTunesRealm()
                    try? realm.write {
                        guard let track = self?.track.entity?.impl else { return }
                        fileURL = track.metadata?.fileURL
                        let metadata = _TrackMetadata(track: track)
                        metadata.updatePreviewURL(url)
                        metadata.duration = Double(duration) / 1000
                        realm.add(metadata, update: true)
                    }
                    subscriber.onNext(fileURL ?? url)
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

    override public func didFinishRequest() -> PlayerItem.RequestState {
        return .done
    }
}

public final class PlayerListItem: PlayerItem {

    override public var name: String? { return playlist.name }

    private let playlist: Playlist

    public var tracks: [PlayerTrackItem] = []

    init(playlist: Playlist) {
        self.playlist = playlist

        super.init()
    }

    override public func fetcher() -> Observable<AVPlayerItem?> {
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
                    self.tracks.append(item)
                    subscriber.onNext(item.fetcher())
                }
                return Disposables.create()
            }.flatMap { $0 }
    }

    override public func didFinishRequest() -> PlayerItem.RequestState {
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

final class Player2: NSObject {

    fileprivate let core: AbstractPlayerKit.Player

    var errorType: ErrorLog.Error.Type = DefaultError.self

    var errorLevel: ErrorLog.Level = DefaultErrorLevel.none

    private(set) lazy var nowPlaying: Observable<Track?> = asObservable(self._nowPlayingTrack)
    private let _nowPlayingTrack = Variable<Track?>(nil)

    private(set) lazy var currentTime: Observable<Float64> = asObservable(self._currentTime)
    private let _currentTime = Variable<Float64>(0)

    var playlingQueue: Observable<[PlayerItem]> {
        return core.items.map { $0.map { $0 as! PlayerItem } }.subscribeOn(MainScheduler.instance)
    }

    var playing: Bool { return queuePlayer.rate != 0 }

    fileprivate var middlewares: [PlayerMiddleware] = []

    private let queuePlayer = AVQueuePlayer()

    override init() {
        core = AbstractPlayerKit.Player(queuePlayer: queuePlayer)

        super.init()
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            queuePlayer.volume = 0.02
            print("simulator")
        #else
            print("iphone")
        #endif

        queuePlayer.addObserver(self, forKeyPath: #keyPath(AVQueuePlayer.currentItem), options: .new, context: nil)
        queuePlayer.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, 600), queue: nil) { [weak self] (time) in
            guard let `self` = self else { return }
            self._currentTime.value = CMTimeGetSeconds(time)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.trackItemGenerateAVPlayerItem(notification:)),
            name: .PlayerTrackItemPrepareForPlay,
            object: nil)
    }

    deinit {
        queuePlayer.removeObserver(self, forKeyPath: #keyPath(AVQueuePlayer.currentItem))
        NotificationCenter.default.removeObserver(self)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        switch keyPath {
        case #keyPath(AVQueuePlayer.currentItem):
            DispatchQueue.main.async {
                var track: Model.Track?
                if let trackId = self.queuePlayer.currentItem?.trackId {
                    track = Model.Track(trackId: trackId)
                }
                self._nowPlayingTrack.value = track?.entity

                if let trackId = track?.trackId {
                    self.middlewares.forEach { $0.willStartPlayTrack(trackId) }
                } else {
                    self.middlewares.forEach { $0.didEndPlay() }
                }
            }
        default:()
        }
    }

    @objc
    private func trackItemGenerateAVPlayerItem(notification: Notification) {
        guard doOnMainThread(execute: self.trackItemGenerateAVPlayerItem(notification: notification)) else { return }
        guard let avPlayerItem = notification.object as? AVPlayerItem else { return }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didEndPlay(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: avPlayerItem)
    }

    func install(middleware: PlayerMiddleware) {
        middlewares.append(middleware)
        middleware.middlewareInstalled(self)
    }

    func play() { core.play() }

    func pause() { core.pause() }

    func advanceToNextItem() { core.advanceToNextItem() }

    func add(track: Model.Track) {
        let item = PlayerTrackItem(track: track)
        core.insert(inPriorityHigh: item)
    }

    func add(playlist: Playlist) {
        let item = PlayerListItem(playlist: playlist)
        core.insert(item, after: nil)
    }

    func removeAll() {
        core.removeAll()
    }
}

extension Player2: Player {

    @objc
    fileprivate func didEndPlay(notification: Notification) {
        guard doOnMainThread(execute: self.didEndPlay(notification: notification)) else { return }

        if let item = notification.object as? AVPlayerItem, let trackId = item.trackId {
            middlewares.forEach { $0.didEndPlayTrack(trackId) }
        }
    }
}

private func configureFading(item: AVPlayerItem) {

    guard let track = item.asset.tracks(withMediaType: AVMediaTypeAudio).first else { return }

    let inputParams = AVMutableAudioMixInputParameters(track: track)

    let fadeDuration = CMTimeMakeWithSeconds(5, 600)
    let fadeOutStartTime = item.asset.duration - fadeDuration
    let fadeInStartTime = kCMTimeZero

    inputParams.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: CMTimeRangeMake(fadeOutStartTime, fadeDuration))
    inputParams.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: CMTimeRangeMake(fadeInStartTime, fadeDuration))

    let audioMix = AVMutableAudioMix()
    audioMix.inputParameters = [inputParams]
    item.audioMix = audioMix
}
