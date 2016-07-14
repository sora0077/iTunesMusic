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


public protocol Player: class {
 
    var nowPlaying: Observable<Track?> { get }
    
    var currentTime: Observable<Float64> { get }
    
    var playlists: [PlaylistType] { get }
    
    func install(middleware middleware: PlayerMiddleware)
    
    func play()
    
    func pause()
    
    func add(track track: Track)
    
    func add(track track: Track, afterPlaylist: Bool)
    
    func add(playlist playlist: PlaylistType)
}


public protocol PlayerMiddleware {
    
    func middlewareInstalled(player: Player)
    
    func willStartPlayTrack(trackId: Int)
    
    func didEndPlayTrack(trackId: Int)
}

extension PlayerMiddleware {
    
    public func middlewareInstalled(player: Player) {}
    
    public func willStartPlayTrack(trackId: Int) {}
    
    public func didEndPlayTrack(trackId: Int) {}
}