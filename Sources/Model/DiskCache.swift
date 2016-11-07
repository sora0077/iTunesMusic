//
//  DiskCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift


extension Model {
    public final class DiskCache {
        static let directory: URL = {
            let base = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let dir = URL(fileURLWithPath: base).appendingPathComponent("tracks", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            return dir
        }()

        public static let shared = DiskCache()

        fileprivate let impl = DiskCacheImpl(dir: DiskCache.directory)

        var dir: URL { return impl.dir }

        fileprivate var downloading: Set<Int> = []
        fileprivate let threshold = 3

        private init() {}

        public var diskSizeInBytes: Int {
            return impl.diskSizeInBytes
        }

        public func removeAll() -> Observable<Void> {
            return impl.removeAll()
        }
    }
}

extension Model.DiskCache: PlayerMiddleware {
    public func didEndPlayTrack(_ trackId: Int) {
        guard canDownload(trackId: trackId) else { return }

        let realm = iTunesRealm()
        guard
            let track = realm.object(ofType: _Track.self, forPrimaryKey: trackId),
            let url = track.metadata?.previewURL,
            let duration = track.metadata?.duration,
            track.metadata?.fileURL == nil else {
                return
        }

        let dir = self.dir
        let filename = url.lastPathComponent

        downloading.insert(trackId)
        URLSession.shared.downloadTask(with: url, completionHandler: { [weak self] (url, response, error) in
            defer {
                _ = self?.downloading.remove(trackId)
            }
            guard let src = url else { return }

            let realm = iTunesRealm()
            guard let track = realm.object(ofType: _Track.self, forPrimaryKey: trackId) else { return }

            do {
                try realm.write {
                    let to = dir.appendingPathComponent(filename)
                    try? FileManager.default.removeItem(at: to)
                    try FileManager.default.moveItem(at: src, to: to)
                    let metadata = _TrackMetadata(track: track)
                    metadata.updateCache(filename: filename)
                    metadata.duration = duration
                    realm.add(metadata, update: true)
                }
            } catch {
                print("\(error)")
            }
        }).resume()
    }

    private func canDownload(trackId: Int) -> Bool {
        if downloading.contains(trackId) { return false }

        let realm = iTunesRealm()
        let cache = realm.object(ofType: _DiskCacheCounter.self, forPrimaryKey: trackId) ?? {
            let cache = _DiskCacheCounter()
            cache.trackId = trackId
            return cache
        }()

        // swiftlint:disable force_try
        try! realm.write {
            cache.counter += 1
            realm.add(cache, update: true)
        }

        guard cache.counter >= threshold else { return false }

        return true
    }
}

extension Model.DiskCache: ReactiveCompatible {}

extension Reactive where Base: Model.DiskCache {
    public var diskSizeInBytes: Observable<Int> {
        return base.impl._diskSizeInBytes.asObservable()
    }
}


private final class DiskCacheImpl: NSObject, NSFilePresenter {

    fileprivate private(set) lazy var _diskSizeInBytes: Variable<Int> = Variable<Int>(self.diskSizeInBytes)

    let dir: URL

    var presentedItemURL: URL? { return dir }
    let presentedItemOperationQueue = OperationQueue()

    init(dir: URL) {
        self.dir = dir
        super.init()

        NSFileCoordinator.addFilePresenter(self)
    }

    func presentedSubitemDidChange(at url: URL) {
        _diskSizeInBytes.value = diskSizeInBytes
    }

    var diskSizeInBytes: Int {
        do {
            let paths = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey])
            let sizes = try paths.map {
                try $0.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            }
            return sizes.reduce(0, +)
        } catch {
            print(error)
            return 0
        }
    }

    func removeAll() -> Observable<Void> {
        let dir = self.dir
        return Observable.create { subscriber in
            do {
                try FileManager.default.removeItem(at: dir)
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
                let realm = iTunesRealm()
                try realm.write {
                    realm.delete(realm.objects(_DiskCacheCounter.self))
                }
                subscriber.onNext(())
                subscriber.onCompleted()
            } catch {
                subscriber.onError(error)
            }
            return Disposables.create()
        }.subscribeOn(SerialDispatchQueueScheduler(qos: .background))
    }
}
