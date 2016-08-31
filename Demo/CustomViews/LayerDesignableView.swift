//
//  LayerDesignableView.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/30.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit


@IBDesignable
class LayerDesignableView: UIView {

    @IBInspectable
    var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    @IBInspectable
    var shadowColor: UIColor? {
        didSet {
            layer.shadowColor = shadowColor?.cgColor
        }
    }

    @IBInspectable
    var shadowOffset: CGSize = .zero {
        didSet {
            layer.shadowOffset = shadowOffset
        }
    }

    @IBInspectable
    var shadowRadius: CGFloat = 0 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }

    @IBInspectable
    var shadowOpacity: Float = 0 {
        didSet {
            layer.shadowOpacity = shadowOpacity
            layer.shouldRasterize = true
            layer.rasterizationScale = UIScreen.main.scale
        }
    }

}
