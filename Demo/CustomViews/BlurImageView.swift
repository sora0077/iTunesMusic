//
//  BlurImageView.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//
import UIKit
import GLKit

final class BlurImageView: GLKView {

    var blurRadius: Float = 0 {
        didSet {
            blurFilter.setValue(blurRadius, forKey: "inputRadius")
            setNeedsDisplay()
        }
    }

    var image: UIImage? {
        didSet {
            inputCIImage = image.map { CIImage(image: $0)! }
        }
    }

    fileprivate var inputCIImage: CIImage? {
        didSet { setNeedsDisplay() }
    }

    fileprivate let clampFilter = CIFilter(name: "CIAffineClamp")!
    fileprivate let blurFilter = CIFilter(name: "CIGaussianBlur")!
    fileprivate let ciContext: CIContext

    override init(frame: CGRect) {
        let glContext = EAGLContext(api: .openGLES2)
        ciContext = CIContext(
            eaglContext: glContext!,
            options: [
                kCIContextWorkingColorSpace: NSNull()
            ]
        )
        super.init(frame: frame, context: glContext!)
        enableSetNeedsDisplay = true
    }

    required init?(coder aDecoder: NSCoder) {
        let glContext = EAGLContext(api: .openGLES2)
        ciContext = CIContext(
            eaglContext: glContext!,
            options: [
                kCIContextWorkingColorSpace: NSNull()
            ]
        )
        super.init(coder: aDecoder)
        context = glContext!
        enableSetNeedsDisplay = true
    }

    override func draw(_ rect: CGRect) {
        if let inputCIImage = inputCIImage {
            clampFilter.setValue(inputCIImage, forKey: kCIInputImageKey)
            blurFilter.setValue(clampFilter.outputImage!, forKey: kCIInputImageKey)
            let rect = CGRect(x: 0, y: 0, width: drawableWidth, height: drawableHeight)
            ciContext.draw(blurFilter.outputImage!, in: rect, from: inputCIImage.extent)
        }
    }
}
