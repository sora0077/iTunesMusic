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
import APIKit


struct WorkerFactory {

    var errorType: ErrorLog.Error.Type!
    var errorLevel: ErrorLog.Level!

    private let generateTrackWorker: ((Model.Track) -> Void)?

    init(_ generateTrackWorker: ((Model.Track) -> Void)? = nil) {
        self.generateTrackWorker = generateTrackWorker
    }

    func track(_ track: Model.Track) -> AnyWorker {
        generateTrackWorker?(track)
        let track = TrackWorker(track: track)
        track.errorType = errorType
        track.errorLevel = errorLevel
        return AnyWorker(track)
    }

    func playlist(_ playlist: Playlist, index: Int = 0) -> AnyWorker {
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

    fileprivate var errorType: ErrorLog.Error.Type!
    fileprivate var errorLevel: ErrorLog.Level!

    init(track: Model.Track) {
        self.track = track
    }

    func run() -> Observable<Response?> {
        func fetchMeta() -> Observable<Void> {
            return Observable<Void>.create { [weak self] subscriber in {
                    guard let `self` = self else { return }

                    self.track.fetch(ifError: self.errorType, level: self.errorLevel) { _ in
                        subscriber.onNext()
                        subscriber.onCompleted()
                    }
                }()
                return Disposables.create()
            }
        }

        let id = self.track.trackId
        return (fetch() ?? fetchMeta().flatMap { [weak self] _ in self?.fetch() ?? .just(nil) })
            .map { [weak self] info in
                defer {
                    self?.canPop = true
                }
                guard let (url, duration) = info else { return nil }
                return (id, url, duration)
            }
    }

    private func fetch() -> Observable<(URL, duration: Double)?>? {
        let id = track.trackId
        guard let track = track.track, track.canPreview else {
            return nil
        }

        if let duration = track.metadata?.duration {
            if let fileURL = track.metadata?.fileURL {
                return .just((fileURL, duration))
            }
            if let url = track.metadata?.previewURL {
                return .just((url, duration))
            }
        }

        let viewURL = track.viewURL
        return Observable.create { subscriber in
            let task = Session.shared.send(GetPreviewUrl(id: id, url: viewURL), callbackQueue: callbackQueue) { result in
                switch result {
                case .success(let (url, duration)):
                    let duration = Double(duration) / 1000
                    let realm = iTunesRealm()
                    try? realm.write {
                        guard let track = realm.object(ofType: _Track.self, forPrimaryKey: id) else { return }
                        let metadata = _TrackMetadata(track: track)
                        metadata.updatePreviewURL(url)
                        metadata.duration = duration
                        realm.add(metadata, update: true)
                    }
                    subscriber.onNext((url, duration))
                    subscriber.onCompleted()
                case .failure(let error):
                    subscriber.onError(error)
                }
            }
            return Disposables.create {
                task?.cancel()
            }
        }.catchErrorJustReturn(nil)
    }
}


private final class PlaylistWorker: Worker {

    typealias Response = PlayerImpl.QueueResponse

    var canPop: Bool = false

    let playlist: Playlist
    var index: Int

    private let factory: WorkerFactory

    private var trackWorker: AnyWorker?

    init(playlist: Playlist, index: Int = 0, factory: WorkerFactory) {
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

                    if playlist.isTrackEmpty || playlist.trackCount <= index {
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
