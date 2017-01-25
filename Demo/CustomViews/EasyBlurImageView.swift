//
//  EasyBlurImageView.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit

fileprivate func convertRadiusKey(_ radius: Float) -> Int {
//    return Int(round(Double(radius * 10)))
    return Int(round(radius))
}

final class EasyBlurImageView: UIImageView {

    override var image: UIImage? {
        didSet {
            if supressDidSet {
                originalImage = image
            } else {
                createBluredImages()
            }
        }
    }

    var blurRadius: Float = 0 {
        didSet {
            setBlurImage()
        }
    }

    fileprivate var supressDidSet: Bool = false
    fileprivate var originalImage: UIImage?
    fileprivate var imageCache: [Int: UIImage] = [:]

    fileprivate let context = CIContext(options: [
        kCIContextWorkingColorSpace: NSNull()
    ])

    deinit {
        print("deinit EasyBlurImageView")
    }

    fileprivate func createBluredImages() {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        #else

            guard let image = self.image.flatMap(CIImage.init) else { return }

            DispatchQueue.global(qos: .background).async {

                for i in 0...20 {
                    let clampFilter = CIFilter(name: "CIAffineClamp")!
                    let blurFilter = CIFilter(name: "CIGaussianBlur")!

                    blurFilter.setValue(i, forKey: "inputRadius")
                    clampFilter.setValue(image, forKey: kCIInputImageKey)
                    blurFilter.setValue(clampFilter.outputImage!, forKey: kCIInputImageKey)
                    let cgImage = self.context.createCGImage(blurFilter.outputImage!, from: image.extent)
                    self.imageCache[i] = UIImage(cgImage: cgImage!)
                }
                DispatchQueue.main.async {
                    self.setBlurImage()
                }
            }
        #endif
    }

    fileprivate func setBlurImage() {
        supressDidSet = true
        defer {
            supressDidSet = false
        }

        #if (arch(i386) || arch(x86_64)) && os(iOS)

        #else
            let key = convertRadiusKey(blurRadius)
            if let image = imageCache[key] {
                self.image = image
                return
            }
            let keys = imageCache.keys.lazy.filter { $0 < key }.sorted()
            for key in keys {
                if let image = imageCache[key] {
                    self.image = image
                    return
                }
            }
            image = originalImage
        #endif
    }
}
