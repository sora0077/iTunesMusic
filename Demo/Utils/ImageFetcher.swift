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

func downloadImage(with url: URL, _ completion: (Result<UIImage, NSError>) -> Void) {
    PINRemoteImageManager.shared().downloadImage(with: url, options: []) { r in
        completion(Result(r.image, failWith: r.error!))
    }
}


extension UIImageView {

    func setArtwork(from artwork: Track, size width: CGFloat) {
        _setArtwork(generator: artwork.artworkURL, size: width)
    }

    func setArtwork(from artwork: iTunesMusic.Collection, size width: CGFloat) {
        _setArtwork(generator: artwork.artworkURL, size: width)
    }

    private func _setArtwork(generator: (Int) -> URL, size width: CGFloat) {

        let size = { Int($0 * UIScreen.main.scale) }

        let thumbnailURL = generator(size(width / 2))
        let artworkURL = generator(size(width))

        pin_setImage(from: thumbnailURL, placeholderImage: nil) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.pin_setImage(from: artworkURL, placeholderImage: result.image)
            }
        }
    }
}
