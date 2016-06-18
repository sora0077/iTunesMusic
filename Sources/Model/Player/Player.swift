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
 
    func play()
    
    func pause()
}

protocol PlayerTypeInternal {
    
    func addPlaylist<Playlist: PlaylistTypeInternal>(playlist: Playlist)
    
    func addPlaylist<Playlist: protocol<PlaylistTypeInternal, PaginatorTypeInternal>>(playlist: Playlist)
}

public let player: Player = PlayerImpl()
