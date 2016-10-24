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
    public final class DiskCache: NSObject, NSFilePresenter {
        public static let shared = DiskCache()

        fileprivate private(set) lazy var _diskSizeInBytes: Variable<Int> = Variable<Int>(self.diskSizeInBytes)

        let dir: URL

        public var presentedItemURL: URL? { return dir }
        public let presentedItemOperationQueue = OperationQueue()

        private override init() {
            let base = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            dir = URL(fileURLWithPath: base).appendingPathComponent("tracks", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)

            super.init()

            NSFileCoordinator.addFilePresenter(self)
        }

        public func presentedSubitemDidChange(at url: URL) {
            _diskSizeInBytes.value = diskSizeInBytes
        }
    }
}

extension Model.DiskCache {
    public var diskSizeInBytes: Int {
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

    public func removeAll() -> Observable<Void> {
        let dir = self.dir
        return Observable.create { subscriber in
            do {
                try FileManager.default.removeItem(at: dir)
                let realm = iTunesRealm()
                try realm.write {
                    realm.delete(realm.objects(_DiskCacheCounter.self))
                }
            } catch {
                subscriber.onError(error)
            }
            return Disposables.create()
        }
    }
}

extension Reactive where Base: Model.DiskCache {
    public var diskSizeInBytes: Observable<Int> {
        return base._diskSizeInBytes.asObservable()
    }
}
