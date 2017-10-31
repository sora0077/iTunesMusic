//
//  ImageFetcher.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/16.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import PINRemoteImage
import PINCache
import Result
import iTunesMusic

func clearAllImageCaches() {
    PINRemoteImageManager.shared().cache.removeAllObjects()
}

func prefetchImages(with urls: [URL]) {
    PINRemoteImageManager.shared().prefetchImages(with: urls)
}

func downloadImage(with url: URL, _ completion: @escaping (Result<UIImage, NSError>) -> Void) {
    PINRemoteImageManager.shared().downloadImage(with: url, options: []) { r in
        completion(Result(r.image, failWith: r.error! as NSError))
    }
}

func cachedImage(with url: URL, _ completion: @escaping (Result<UIImage?, NSError>) -> Void) {
    let cache = PINRemoteImageManager.shared()
    cache.imageFromCache(with: url, processorKey: nil, options: []) { r in
        if let error = r.error {
            completion(.failure(error as NSError))
        } else {
            completion(.success(r.image))
        }
    }
}

private struct UIImageViewKey {
    static var itm_imageURL: UInt8 = 0
}

extension UIImageView {

    fileprivate var itm_imageURL: URL? {
        set {
            objc_setAssociatedObject(self, &UIImageViewKey.itm_imageURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &UIImageViewKey.itm_imageURL) as? URL
        }
    }
}

private var localCache: [Int: [Int: URL]] = [:]
extension UIImageView {

    func setArtwork(of artwork: Track, size width: CGFloat) {
        _setArtwork(id: artwork.collection.id, generator: artwork.artworkURL, size: width)
    }

    func setArtwork(of artwork: iTunesMusic.Collection, size width: CGFloat) {
        _setArtwork(id: artwork.id, generator: artwork.artworkURL, size: width)
    }

    private func _setArtwork(id: Int, generator: @escaping (Int) -> URL, size width: CGFloat) {
        guard doOnMainThread(execute: self._setArtwork(id: id, generator: generator, size: width)) else {
            return
        }
        let size = { Int($0 * UIScreen.main.scale) }

        let thumbnailURL = generator(size(width / 2))
        let artworkURL = generator(size(width))

        var imageURLs: [(size: Int, url: URL)] = [(size(width / 2), thumbnailURL), (size(width), artworkURL)]
        let isNotContained = { !imageURLs.lazy.map { $1 }.contains($0) }

        if let (key, cachedURL) = localCache[id]?.lazy.sorted(by: { $0.key > $1.key }).first, isNotContained(cachedURL) {
            imageURLs.insert((key, cachedURL), at: 0)
        }

        if itm_imageURL.map(isNotContained) ?? false {
            image = nil
            setNeedsLayout()
        }

        func setImage(from urls: ArraySlice<(size: Int, url: URL)>, placeholder: UIImage? = nil) {
            guard !urls.isEmpty else { return }
            var urls = urls
            let (size, url) = urls[urls.startIndex]
            itm_imageURL = url
            pin_setImage(from: url, placeholderImage: placeholder) { [weak self] result in
                if result.image != nil {
                    var cache = localCache.removeValue(forKey: id) ?? [:]
                    cache[size] = url
                    localCache[id] = cache
                }
                DispatchQueue.main.async {
                    if url == self?.itm_imageURL {
                        setImage(from: urls.dropFirst(), placeholder: result.image)
                    }
                }
            }
        }
        setImage(from: ArraySlice(imageURLs))
    }
}
