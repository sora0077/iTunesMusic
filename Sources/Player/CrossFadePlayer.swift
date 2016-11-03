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

    override var state: State {
        didSet {
            print("track", state)
            if case .requesting = state {
                fetch()
            }
        }
    }

    init(track: Model.Track) {
        self.track = track

        super.init()
    }

    fileprivate func fetch(_ completion: @escaping (State) -> Void = { _ in }) {
        guard let track = track.entity, track.canPreview else {
            state = .rejected
            completion(state)
            return
        }

        if (track.metadata?.fileURL != nil) || (track.metadata?.previewURL != nil) {
            state = .readyForPlay
            completion(state)
            return
        }
        let id = track.id
        Session.shared.send(GetPreviewUrl(id: id, url: track.viewURL), callbackQueue: callbackQueue) { [weak self] result in
            switch result {
            case .success(let (url, duration)):
                let realm = iTunesRealm()
                try? realm.write {
                    guard let track = realm.object(ofType: _Track.self, forPrimaryKey: id) else { return }
                    let metadata = _TrackMetadata(track: track)
                    metadata.updatePreviewURL(url)
                    metadata.duration = Double(duration) / 1000
                    realm.add(metadata, update: true)
                }
                self?.state = .readyForPlay
                self?.isRequestFinished = true
                completion(.readyForPlay)
            case .failure:
                self?.state = .rejected
                completion(.rejected)
            }
        }?.resume()
    }

    override func generateAVPlayerItem(_ completion: @escaping (AVPlayerItem) -> Void) {
        guard let track = track.entity, track.canPreview else {
            state = .rejected
            return
        }
        guard let url = track.metadata?.fileURL ?? track.metadata?.previewURL else {
            state = .rejected
            return
        }

        let asset = AVURLAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            let item = AVPlayerItem(asset: asset)
            completion(item)
        }
    }
}

private final class PlayerListItem: PlayerItem {

    override var state: State {
        didSet {
            print("playlist", state)
            if case .requesting = state {
                fetch()
            }
        }
    }

    private let playlist: Playlist

    private var caret: Int = 0
    private var items: [PlayerTrackItem] = []

    init(playlist: Playlist) {
        self.playlist = playlist

        super.init()
    }

    private func fetch() {
        guard doOnMainThread(execute: self.fetch()) else { return }

        if playlist.isTrackEmpty || playlist.trackCount <= caret {
            state = .rejected
            return
        }
        if let paginator = playlist as? _Fetchable,
            !paginator._hasNoPaginatedContents && playlist.trackCount - caret < 3 {
            if !paginator._requesting.value {
                paginator.fetch(ifError: DefaultError.self, level: DefaultErrorLevel.none) { [weak self] error in
                    self?.state = .prepareForRequest
                }
            }
            return
        }
        let track = Model.Track(track: playlist.track(at: caret))
        let item = PlayerTrackItem(track: track)
        print(caret, track.entity?.name ?? "")
        items[safe: caret] = item
        item.fetch { [weak self] state in
            if case .readyForPlay = state {
                self?.state = .readyForPlay
            }
        }
    }

    override func generateAVPlayerItem(_ completion: @escaping (AVPlayerItem) -> Void) {
        defer {
            caret += 1
            state = .prepareForRequest
        }
        if let item = items[safe: caret] {
            item.generateAVPlayerItem(completion)
        }
    }
}

private extension Array {
    subscript (safe index: Int) -> Element? {
        set {
            if indices.contains(index) {
                if let val = newValue {
                    self[index] = val
                } else {
                    remove(at: index)
                }
            } else if let val = newValue {
                append(val)
            }
        }
        get {
            if indices.contains(index) {
                return self[index]
            }
            return nil
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

    fileprivate let core: AbstractPlayerKit.Player<PlayerItem>

    fileprivate var items: [PlayerItem] = []

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

    override init() {
        core = AbstractPlayerKit.Player<PlayerItem>(core: queuePlayer)
        super.init()

        #if (arch(i386) || arch(x86_64)) && os(iOS)
            queuePlayer.volume = 0.02
            print("simulator")
        #else
            print("iphone")
        #endif
        queuePlayer.addObserver(self, forKeyPath: #keyPath(AVQueuePlayer.status), options: .new, context: nil)
    }

    deinit {
        queuePlayer.removeObserver(self, forKeyPath: #keyPath(AVQueuePlayer.status))
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }

        switch keyPath {
        case #keyPath(AVQueuePlayer.status):
            switch queuePlayer.status {
            case .readyToPlay:
                queuePlayer.play()
            default:()
            }
        default:()
        }
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
        core.insert(atFirst: item)
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
