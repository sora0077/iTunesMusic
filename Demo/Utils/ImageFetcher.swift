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
        if let image = r.image {
            completion(.success(image))
        } else {
            completion(.failure(r.error as! NSError))
        }
    }
}

fileprivate final class Wrapper<T> {
    let value: T
    init(_ value: T) { self.value = value }
}

fileprivate struct UIImageViewKey {
    static var itm_imageURL: UInt8 = 0
}

extension UIImageView {

    fileprivate var itm_imageURL: URL? {
        set {
            objc_setAssociatedObject(self, &UIImageViewKey.itm_imageURL, newValue.map(Wrapper.init), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return (objc_getAssociatedObject(self, &UIImageViewKey.itm_imageURL) as? Wrapper<URL>)?.value
        }
    }
}

extension UIImageView {

    func setArtwork(of artwork: Track, size width: CGFloat) {
        _setArtwork(generator: artwork.artworkURL, size: width)
    }

    func setArtwork(of artwork: iTunesMusic.Collection, size width: CGFloat) {
        _setArtwork(generator: artwork.artworkURL, size: width)
    }

    fileprivate func _setArtwork(generator: @escaping (Int) -> URL, size width: CGFloat) {
        guard doOnMainThread(execute: self._setArtwork(generator: generator, size: width)) else {
            return
        }

        let size = { Int($0 * UIScreen.main.scale) }

        let thumbnailURL = generator(size(width / 2))
        let artworkURL = generator(size(width))

        if thumbnailURL != itm_imageURL {
            image = nil
            setNeedsLayout()
        }
        itm_imageURL = thumbnailURL
        pin_setImage(from: thumbnailURL, placeholderImage: nil) { [weak self] result in
            DispatchQueue.main.async {
                if thumbnailURL == self?.itm_imageURL {
                    self?.itm_imageURL = artworkURL
                    self?.pin_setImage(from: artworkURL, placeholderImage: result.image)
                }
            }
        }
    }
}
