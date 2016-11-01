//
//  CrossFadePlayer.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import RxSwift
import ErrorEventHandler
import RealmSwift


private class PlayerItem {

}

private final class PlayerTrackItem: PlayerItem {

}

private final class PlayerListItem: PlayerItem {

}

private enum DefaultError: ErrorLog.Error {
    case none

    init(error: Swift.Error?) {
        self = .none
    }
}

private enum DefaultErrorLevel: ErrorLog.Level {
    case none
}

final class Player2: NSObject {
    var errorType: ErrorLog.Error.Type = DefaultError.self

    var errorLevel: ErrorLog.Level = DefaultErrorLevel.none

    var nowPlaying: Observable<Track?> {
        return Observable.just(nil)
    }

    var currentTime: Observable<Float64> {
        return Observable.just(1)
    }

    var playlingQueue: Observable<[Model.Track]> {
        return Observable.just([])
    }

    var playing: Bool = false

    func install(middleware: PlayerMiddleware) {

    }

    func play() {

    }

    func pause() {

    }

    func nextTrack() {

    }

    func add(track: Model.Track) {

    }

    func add(playlist: Playlist) {

    }

    func removeAll() {

    }
}

extension Player2: Player {

}
