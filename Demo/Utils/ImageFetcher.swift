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
        // swiftlint:disable force_cast
        completion(Result(r.image, failWith: r.error as! NSError))
    }
}

fileprivate struct UIImageViewKey {
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

fileprivate var localCache: [Int: [Int: URL]] = [:]

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

        let placeholderURL = localCache[id]?.sorted(by: { $0.key > $1.key }).first?.value
        let size = { Int($0 * UIScreen.main.scale) }

        let thumbnailURL = generator(size(width / 2))
        let artworkURL = generator(size(width))

        var imageURLs = [thumbnailURL, artworkURL]
        if let url = placeholderURL, ![thumbnailURL, artworkURL].contains(url) {
            imageURLs = [url, thumbnailURL, artworkURL]
        }

        localCache[id] = localCache[id] ?? [:]
        localCache[id]![size(width / 2)] = thumbnailURL
        localCache[id]![size(width)] = artworkURL

        if let url = itm_imageURL, !imageURLs.contains(url) {
            image = nil
            setNeedsLayout()
        }
        _setImage(from: imageURLs)
    }

    private func _setImage(from urls: [URL], placeholder: UIImage? = nil) {
        guard !urls.isEmpty else { return }

        var urls = urls
        let url = urls.remove(at: 0)
        itm_imageURL = url
        pin_setImage(from: url, placeholderImage: placeholder) { [weak self] result in
            DispatchQueue.main.async {
                if url == self?.itm_imageURL {
                    self?._setImage(from: urls, placeholder: result.image)
                }
            }
        }
    }
}
