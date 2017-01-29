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
        public static let shared = DiskCache(dir: Settings.Track.Cache.directory)

        fileprivate let impl: DiskCacheImpl

        fileprivate var downloading: Set<Int> = []
        fileprivate let threshold = 3

        private init(dir: URL) {
            impl = DiskCacheImpl(dir: dir)
        }

        public var diskSizeInBytes: Int {
            return impl.diskSizeInBytes
        }

        public func removeAll() -> Observable<Void> {
            return impl.removeAll()
        }
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
        return Observable.empty()
    }
}
