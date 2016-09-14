//
//  Color.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/09/14.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit


extension UIColor {

    convenience init(hex: Int, alpha: CGFloat = 1) {
        let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(hex & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
