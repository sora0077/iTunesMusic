//
//  ArtistDetailViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic


final class ArtistDetailViewController: UIViewController {
    
    private let artist: Model.Artist
    
    init(artist: Artist) {
        self.artist = Model.Artist(artist: artist)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
    }
}
