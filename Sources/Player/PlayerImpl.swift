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

    var errorType: ErrorLog.Error.Type = DefaultError.self {
        didSet {
            workerFactory.errorType = errorType
        }
    }
    var errorLevel: ErrorLog.Level = DefaultErrorLevel.none {
        didSet {
            workerFactory.errorLevel = errorLevel
        }
    }

    fileprivate let _player = AVQueuePlayer()

    private(set) lazy var nowPlaying: Observable<Track?> = asObservable(self._nowPlayingTrack)
    private let _nowPlayingTrack = Variable<Track?>(nil)

    private(set) lazy var currentTime: Observable<Float64> = asObservable(self._currentTime)
    private let _currentTime = Variable<Float64>(0)

    fileprivate var _installs: [PlayerMiddleware] = []

    var playing: Bool { return _player.rate != 0 }

    fileprivate var queueController: QueueController<QueueResponse>!
    private let queueuingCount = Variable<Int>(0)


    fileprivate let workerFactory: WorkerFactory


    init(previewer: Preview) {
        workerFactory = WorkerFactory(preview: previewer)
        workerFactory.errorType = errorType
        workerFactory.errorLevel = errorLevel

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
            name: .AVPlayerItemDidPlayToEndTime,
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
        _add(worker: workerFactory.track(track))
    }

    func add(playlist: PlaylistType) {
        _add(worker: workerFactory.playlist(playlist))
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
