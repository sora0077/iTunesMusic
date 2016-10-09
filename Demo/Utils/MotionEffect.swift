//
//  MotionEffect.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/09.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import UIKit


extension UIInterpolatingMotionEffect {

    enum Tilt {
        case background(depth: CGFloat)
        case front(depth: CGFloat)

        fileprivate var minimumValue: CGFloat {
            switch self {
            case .background(depth: let depth):
                return depth
            case .front(depth: let depth):
                return -depth
            }
        }
        fileprivate var maximumValue: CGFloat {
            return -minimumValue
        }
    }
}


extension UIView {

    func addTiltEffects(tilt: UIInterpolatingMotionEffect.Tilt) {
        let xAxis = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        let yAxis = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        xAxis.minimumRelativeValue = tilt.minimumValue
        xAxis.maximumRelativeValue = tilt.maximumValue
        yAxis.minimumRelativeValue = tilt.minimumValue * 2
        yAxis.maximumRelativeValue = tilt.maximumValue * 2
        let effect = UIMotionEffectGroup()
        effect.motionEffects = [xAxis, yAxis]
        addMotionEffect(effect)
    }
}
