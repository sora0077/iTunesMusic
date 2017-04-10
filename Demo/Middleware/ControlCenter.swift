//
//  ControlCenter.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/14.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer
import iTunesMusic
import RxSwift
import NotificationCenter

final class ControlCenter: NSObject, PlayerMiddleware {
    fileprivate weak var player: Player?

    fileprivate let disposeBag = DisposeBag()

    fileprivate var currentTrackId: Int?

    private var nowPlayingInfo: [String: Any]? = nil {
        didSet {
            DispatchQueue.main.async {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
            }
        }
    }

    func middlewareInstalled(_ player: Player) {
        self.player = player

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(self.togglePlayPause))
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.playCommand.addTarget(self, action: #selector(self.play))
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(self.pause))
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(self.nextTrackCommand))
        commandCenter.nextTrackCommand.isEnabled = true

        commandCenter.bookmarkCommand.addTarget(self, action: #selector(self.bookmark))
        commandCenter.bookmarkCommand.isEnabled = true
//        commandCenter.skipBackwardCommand.addTarget(self, action: "skipBackward")
//        commandCenter.skipBackwardCommand.enabled = true

        player.currentTime
            .asObservable()
            .map(Int.init)
            .distinctUntilChanged()
            .filter { $0 == 45 }
            .subscribe(onNext: { [weak self] time in
                print(time)
                if self?.currentTrackId == self?.nowPlayingInfo?["currentTrackId"] as? Int {
                    self?.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
                }
            })
            .addDisposableTo(disposeBag)
    }

    func willStartPlayTrack(_ trackId: Int) {
        guard doOnMainThread(execute: self.willStartPlayTrack(trackId)) else { return }
        guard let track = Model.Track(trackId: trackId).entity else { return }

        currentTrackId = trackId

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.bookmarkCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.name,
            MPMediaItemPropertyArtist: track.artist.name,
            MPMediaItemPropertyAlbumTitle: track.collection.name,
            MPNowPlayingInfoPropertyPlaybackRate: 1,
            MPMediaItemPropertyPlaybackDuration: track.metadata?.duration ?? 0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
            "currentTrackId": trackId
        ]
        let size = UIScreen.main.bounds.size
        let artworkURL = track.artworkURL(size: Int(min(size.width, size.height) * UIScreen.main.scale))
        self.nowPlayingInfo = info
        downloadImage(with: artworkURL) { [weak self] result in
            guard let `self` = self else { return }
            guard case .success(let image) = result else { return }

            if trackId == self.nowPlayingInfo?["currentTrackId"] as? Int {
                info["artworkImage"] = image
                info[MPMediaItemPropertyArtwork] = {
                    if #available(iOS 10.0, *) {
                        return MPMediaItemArtwork(boundsSize: size) { _ in
                            return image
                        }
                    } else {
                        return MPMediaItemArtwork(image: image)
                    }
                }()
                self.nowPlayingInfo = info
            }
        }
    }

    func didEndPlay() {
        guard doOnMainThread(execute: self.didEndPlay()) else { return }
        nowPlayingInfo = nil

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.bookmarkCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
    }

    @objc
    fileprivate func togglePlayPause() {
        guard let player = player else { return }
        if player.playing {
            pause()
        } else {
            play()
        }
    }
    @objc
    fileprivate func play() {
        player?.play()
        nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1
    }
    @objc
    fileprivate func pause() {
        player?.pause()
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Int(player?.currentTime.value ?? 0)
        nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
    }
    @objc
    fileprivate func nextTrackCommand() {
        player?.advanceToNextItem()

    }

    @objc
    fileprivate func bookmark() {
        guard let trackId = currentTrackId else { return }
        guard let track = Model.Track(trackId: trackId).entity else { return }

        let playlist = Model.MyPlaylist(playlist: Model.MyPlaylists()[0])
        playlist.append(track: track)
    }
//    @objc
//    fileprivate func skipBackward() {
//
//    }
}
