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

    var playing: Bool { get }

    var playlists: [PlaylistType] { get }

    func install(middleware: PlayerMiddleware)

    func play()

    func pause()

    func nextTrack()

    func add(track: Track)

    func add(track: Track, afterPlaylist: Bool)

    func add(playlist: PlaylistType)
}


public protocol PlayerMiddleware {

    func middlewareInstalled(_ player: Player)

    func willStartPlayTrack(_ trackId: Int)

    func didEndPlayTrack(_ trackId: Int)

    func didEndPlay()
}

extension PlayerMiddleware {

    public func middlewareInstalled(_ player: Player) {}

    public func willStartPlayTrack(_ trackId: Int) {}

    public func didEndPlayTrack(_ trackId: Int) {}

    public func didEndPlay() {}
}
