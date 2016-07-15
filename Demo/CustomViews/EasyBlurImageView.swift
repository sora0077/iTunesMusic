//
//  EasyBlurImageView.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit


private func convertRadiusKey(radius: Float) -> Int {
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

    private var supressDidSet: Bool = false
    private var originalImage: UIImage?
    private var imageCache: [Int: UIImage] = [:]
    
    private let context = CIContext(options: [
        kCIContextWorkingColorSpace: NSNull()
    ])

    private func createBluredImages() {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        #else
        
        guard let image = self.image.flatMap(CIImage.init) else { return }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
            for i in 0...20 {
                let clampFilter = CIFilter(name: "CIAffineClamp")!
                let blurFilter = CIFilter(name: "CIGaussianBlur")!
                
                blurFilter.setValue(i, forKey: "inputRadius")
                clampFilter.setValue(image, forKey: kCIInputImageKey)
                blurFilter.setValue(clampFilter.outputImage!, forKey: kCIInputImageKey)
                let cgImage = self.context.createCGImage(blurFilter.outputImage!, fromRect: image.extent)
                self.imageCache[i] = UIImage(CGImage: cgImage)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.setBlurImage()
            }
        }
        #endif
    }
    
    private func setBlurImage() {
        supressDidSet = true
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            
        #else
            image = imageCache[convertRadiusKey(blurRadius)]
        #endif
        supressDidSet = false
    }
}