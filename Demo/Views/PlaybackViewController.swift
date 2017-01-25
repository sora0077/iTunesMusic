//
//  PlaybackViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/17.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic

private final class InnerShadowView: UIView {

    private var shadowLayer = CALayer()

    override func layoutSubviews() {
        super.layoutSubviews()

        makeShadow(to: self)
    }

    func makeShadow(to view: UIView) {
        let sublayer = CALayer()
        shadowLayer.removeFromSuperlayer()
        shadowLayer = sublayer

        sublayer.frame = view.bounds
        view.layer.addSublayer(sublayer)
        sublayer.masksToBounds = true

        let width: CGFloat = 20

        let size = sublayer.bounds.size
        var point = CGPoint(x: -width, y: -width)

        let path = CGMutablePath()
        path.move(to: point)
        point.x += size.width + width
        path.addLine(to: point)
        point.y += width
        path.addLine(to: point)
        point.x -= size.width
        path.addLine(to: point)
        point.y += size.height
        path.addLine(to: point)
        point.x -= width
        path.addLine(to: point)
        point.y -= size.height + width
        path.addLine(to: point)

        path.closeSubpath()

        sublayer.shadowOffset = CGSize(width: 10, height: 10)
        sublayer.shadowOpacity = 0.8
        sublayer.shadowRadius = 10
        sublayer.shadowPath = path
    }
}

final class PlaybackViewController: UIViewController {

    private let artworkImageView = UIImageView()
    private let shadowView = InnerShadowView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(artworkImageView)
        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.snp.makeConstraints { make in
            make.top.equalTo(-20)
            make.bottom.equalTo(20)
            make.left.right.equalTo(-20)
        }
        artworkImageView.addTiltEffects(tilt: .background(depth: 10))
        artworkImageView.layer.zPosition = -1000

        view.addSubview(shadowView)
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
    }

    func setArtwork(of collection: iTunesMusic.Collection, size: CGFloat) {
        //animator.fractionComplete = 0.9
        artworkImageView.setArtwork(of: collection, size: size)
    }
}
