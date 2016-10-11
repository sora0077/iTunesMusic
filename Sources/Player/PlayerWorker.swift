//
//  PlayerWorker.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/11.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import RxSwift
import RealmSwift
import ErrorEventHandler
import AbstractPlayerKit


struct WorkerFactory {

    fileprivate let preview: Preview
    var errorType: ErrorLog.Error.Type!
    var errorLevel: ErrorLog.Level!

    private let generateTrackWorker: ((Model.Track) -> Void)?

    init(preview: Preview, generateTrackWorker: ((Model.Track) -> Void)? = nil) {
        self.preview = preview
        self.generateTrackWorker = generateTrackWorker
    }

    func track(_ track: Model.Track) -> AnyWorker {
        generateTrackWorker?(track)
        let track = TrackWorker(track: track)
        track.preview = preview
        track.errorType = errorType
        track.errorLevel = errorLevel
        return AnyWorker(track)
    }

    func playlist(_ playlist: PlaylistType, index: Int = 0) -> AnyWorker {
        let playlist = PlaylistWorker(playlist: playlist, index: index, factory: self)
        return AnyWorker(playlist)
    }
}


private class _AnyWorkerBase<Response>: Worker {
    var canPop: Bool { fatalError() }
    func run() -> Observable<Response?> { fatalError() }
}

private final class _AnyWorker<W: Worker>: _AnyWorkerBase<W.Response> {

    let worker: W

    init(worker: W) {
        self.worker = worker
    }

    override var canPop: Bool { return worker.canPop }
    override func run() -> Observable<W.Response?> { return worker.run() }
}

final class AnyWorker: Worker {

    typealias Response = PlayerImpl.QueueResponse

    private let base: _AnyWorkerBase<Response>

    fileprivate init<W: Worker>(_ base: W) where W.Response == Response {
        self.base = _AnyWorker(worker: base)
    }

    var canPop: Bool { return base.canPop }
    func run() -> Observable<Response?> { return base.run() }
}

private final class TrackWorker: Worker {

    typealias Response = PlayerImpl.QueueResponse

    var canPop: Bool = false

    let track: Model.Track
    fileprivate var preview: Preview!

    fileprivate var errorType: ErrorLog.Error.Type!
    fileprivate var errorLevel: ErrorLog.Level!

    init(track: Model.Track) {
        self.track = track
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

    private let factory: WorkerFactory

    private var trackWorker: AnyWorker?

    init(playlist: PlaylistType, index: Int = 0, factory: WorkerFactory) {
        self.playlist = playlist
        self.index = index

        self.factory = factory
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
                            paginator.fetch(ifError: self.factory.errorType, level: self.factory.errorLevel) { error in
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
                    let worker = self.factory.track(Model.Track(track: playlist.track(at: index)))
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
