//
//  PlayerImpl.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import RxSwift
import RealmSwift
import ErrorEventHandler
import AbstractPlayerKit


private final class TrackWorker: Worker {

    typealias Response = PlayerImpl.QueueResponse

    var canPop: Bool = false

    let track: Model.Track
    let preview: Preview

    private let errorType: ErrorLog.Error.Type
    private let errorLevel: ErrorLog.Level

    init(track: Model.Track, preview: Preview, errorType: ErrorLog.Error.Type, errorLevel: ErrorLog.Level) {
        self.track = track
        self.preview = preview

        self.errorType = errorType
        self.errorLevel = errorLevel
    }

    func run() -> Observable<Response?> {
        func getPreviewInfo(track: Track) -> (URL, Double)? {
            print(track.id, track.name)
            if let duration = track.metadata?.duration {
                if let url = track.metadata?.fileURL {
                    return (url, duration)
                }
                if let url = track.metadata?.previewURL {
                    return (url, duration)
                }
            }
            return nil
        }

        func fetchPreviewInfo() -> Observable<(URL, duration: Double)?>? {
            guard let track = track.track else { return nil }

            if let info = getPreviewInfo(track: track) {
                return Observable.just(info)
            }

            return preview.queueing(track: track).fetch().map { $0 }
        }

        func fetchMeta() -> Observable<Void> {
            return Observable<Void>.create { [weak self] subscriber in
                func inner() {
                    guard let `self` = self else { return }

                    self.track.fetch(ifError: self.errorType, level: self.errorLevel) { _ in
                        subscriber.onNext()
                        subscriber.onCompleted()
                    }
                }
                inner()
                return Disposables.create()
            }
        }

        let id = self.track.trackId
        return (fetchPreviewInfo() ?? fetchMeta().flatMap { _ in fetchPreviewInfo() ?? .just(nil) })
            .map { [weak self] option in
                defer {
                    self?.canPop = true
                }
                guard let (url, duration) = option else { return nil }
                return (id, url, duration)
            }
    }
}


private final class PlaylistWorker: Worker {

    typealias Response = PlayerImpl.QueueResponse

    var canPop: Bool = false

    let playlist: PlaylistType
    var index: Int
    let preview: Preview

    private let errorType: ErrorLog.Error.Type
    private let errorLevel: ErrorLog.Level

    private var trackWorker: TrackWorker?

    init(playlist: PlaylistType, index: Int = 0, preview: Preview, errorType: ErrorLog.Error.Type, errorLevel: ErrorLog.Level) {
        self.playlist = playlist
        self.index = index
        self.preview = preview

        self.errorType = errorType
        self.errorLevel = errorLevel
    }

    func run() -> Observable<Response?> {
        return Observable<Observable<Response?>>
            .create { [weak self] subscriber in
                DispatchQueue.main.async {
                    guard let `self` = self else { return }

                    let index = self.index
                    let playlist = self.playlist

                    if playlist.isTrackEmpty || playlist.trackCount < index {
                        self.canPop = true
                        subscriber.onNext(Observable.just(nil))
                        subscriber.onCompleted()
                        return
                    }
                    if let paginator = playlist as? _Fetchable,
                        !paginator._hasNoPaginatedContents && playlist.trackCount - index < 3 {
                        if !paginator._requesting.value {
                            paginator.fetch(ifError: self.errorType, level: self.errorLevel) { error in
                                if error != nil {
                                    self.canPop = true
                                }
                                subscriber.onNext(Observable.just(nil))
                                subscriber.onCompleted()
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                subscriber.onNext(Observable.just(nil))
                                subscriber.onCompleted()
                            }
                        }
                        return
                    }
                    let track = Model.Track(track: playlist.track(at: index))
                    let worker = TrackWorker(track: track, preview: self.preview,
                                             errorType: self.errorType, errorLevel: self.errorLevel)
                    self.trackWorker = worker
                    self.index += 1

                    subscriber.onNext(worker.run())
                    subscriber.onCompleted()
                }
                return Disposables.create()
            }
            .flatMap { $0 }
    }
}


fileprivate extension AVPlayerItem {

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


final class PlayerImpl: NSObject, Player {
    private enum DefaultError: ErrorLog.Error {
        case none

        init(error: Swift.Error?) {
            self = .none
        }
    }
    private enum DefaultErrorLevel: ErrorLog.Level {
        case none
    }

    typealias QueueResponse = (id: Int, url: URL, duration: Double)

    var playlists: [PlaylistType] { return [] }

    var errorType: ErrorLog.Error.Type = DefaultError.self

    var errorLevel: ErrorLog.Level = DefaultErrorLevel.none

    fileprivate let _player = AVQueuePlayer()

    private(set) lazy var nowPlaying: Observable<Track?> = asObservable(self._nowPlayingTrack)
    private let _nowPlayingTrack = Variable<Track?>(nil)

    private(set) lazy var currentTime: Observable<Float64> = asObservable(self._currentTime)
    private let _currentTime = Variable<Float64>(0)

    fileprivate var _installs: [PlayerMiddleware] = []

    var playing: Bool { return _player.rate != 0 }

    fileprivate let previewer: Preview

    fileprivate var queueController: QueueController<QueueResponse>!
    private let queueuingCount = Variable<Int>(0)

    init(previewer: Preview) {
        self.previewer = previewer
        super.init()

        queueController = QueueController(queueingCount: queueuingCount.asObservable()) { [weak self] id, url, duration in
            self?.configureNextPlayerItem(id: id, url: url, duration: duration)
        }
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            _player.volume = 0.02
            print("simulator")
        #else
            print("iphone")
        #endif
        _player.addObserver(self, forKeyPath: #keyPath(AVQueuePlayer.status), options: [.new, .old], context: nil)
        _player.addObserver(self, forKeyPath: #keyPath(AVQueuePlayer.currentItem), options: [.new, .old], context: nil)

        //        _player.currentTime()
        _player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, 600), queue: nil) { [weak self] (time) in
            guard let `self` = self else { return }
            self._currentTime.value = CMTimeGetSeconds(time)
        }
    }

    deinit {
        [#keyPath(AVQueuePlayer.status), #keyPath(AVQueuePlayer.currentItem)].forEach {
            _player.removeObserver(self, forKeyPath: $0)
        }

        NotificationCenter.default.removeObserver(self)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        guard let keyPath = keyPath else { return }

        switch keyPath {
        case "status":
            if _player.status == .readyToPlay {
                _player.play()
            }
        case "currentItem":

            DispatchQueue.main.async {
                let realm = iTunesRealm()
                var track: Track?
                if let trackId = self._player.currentItem?.trackId {
                    track = realm.object(ofType: _Track.self, forPrimaryKey: trackId)
                }
                self._nowPlayingTrack.value = track

                if let trackId = self._player.currentItem?.trackId {
                    self._installs.forEach { $0.willStartPlayTrack(trackId) }
                } else {
                    self._installs.forEach { $0.didEndPlay() }
                }
            }

            queueuingCount.value = _player.items().count
            if _player.currentItem == nil {
                pause()
            }
        default:
            break
        }
    }

    func install(middleware: PlayerMiddleware) {
        _installs.append(middleware)
        middleware.middlewareInstalled(self)
    }

    func play() { _player.play() }

    func pause() { _player.pause() }

    func nextTrack() { _player.advanceToNextItem() }

    private func configureNextPlayerItem(id: Int, url: URL, duration: Double) {
        let item = AVPlayerItem(asset: AVAsset(url: url))
        item.trackId = id

        print("next play ", id)

        configureFading(item: item, duration: duration)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.didEndPlay),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item
        )

        _player.insert(item, after: nil)
        queueuingCount.value = _player.items().count
        if self._player.status == .readyToPlay {
            self.play()
        }
    }

    @objc
    private func didEndPlay(_ notification: Foundation.Notification) {
        assert(Thread.isMainThread)

        if let item = notification.object as? AVPlayerItem, let trackId = item.trackId {
            _installs.forEach { $0.didEndPlayTrack(trackId) }
        }
        if _player.items().count == 1 {
            pause()
        }
    }
}


// add/(remove)
extension PlayerImpl {

    func add(track: Model.Track) {
        let worker = TrackWorker(track: track, preview: previewer,
                                 errorType: errorType, errorLevel: errorLevel)
        _add(worker: worker)
    }

    func add(playlist: PlaylistType) {
        let worker = PlaylistWorker(playlist: playlist, preview: previewer,
                                    errorType: errorType, errorLevel: errorLevel)
        _add(worker: worker)
    }

    private func _add<W: Worker>(worker: W) where W.Response == QueueResponse {
        if _player.status == .readyToPlay, !playing {
            play()
        }

        queueController.add(worker)
    }
}

private func configureFading(item: AVPlayerItem, duration: Double) {

    guard let track = item.asset.tracks(withMediaType: AVMediaTypeAudio).first else { return }

    let inputParams = AVMutableAudioMixInputParameters(track: track)

    let fadeDuration = CMTimeMakeWithSeconds(5, 600)
    let fadeOutStartTime = CMTimeMakeWithSeconds(duration - 5, 600)
    let fadeInStartTime = CMTimeMakeWithSeconds(0, 600)

    inputParams.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: CMTimeRangeMake(fadeOutStartTime, fadeDuration))
    inputParams.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: CMTimeRangeMake(fadeInStartTime, fadeDuration))

    let audioMix = AVMutableAudioMix()
    audioMix.inputParameters = [inputParams]
    item.audioMix = audioMix
}
