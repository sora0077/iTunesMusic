//
//  Player.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import RxSwift
import RealmSwift


public protocol Player {
 
    var nowPlaying: Observable<Track?> { get }
    
    var currentTime: Observable<Float64> { get }
    
    func play()
    
    func pause()

    func add(track track: Track)
    
    func add(playlist playlist: PlaylistType)
}

public let player: Player = PlayerImpl()
