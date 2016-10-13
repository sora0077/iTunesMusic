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
import ErrorEventHandler



public protocol Player: class {

    var errorType: ErrorLog.Error.Type { get set }

    var errorLevel: ErrorLog.Level { get set }

    var nowPlaying: Observable<Track?> { get }

    var currentTime: Observable<Float64> { get }

    var playing: Bool { get }

    var playlingQueue: Observable<[Model.Track]> { get }

    func install(middleware: PlayerMiddleware)

    func play()

    func pause()

    func nextTrack()

    func add(track: Model.Track)

    func add(playlist: PlaylistType)

    func removeAll()
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
