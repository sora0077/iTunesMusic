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
import SDWebImage


final class ControlCenter: NSObject, PlayerMiddleware {
    private weak var player: Player?
    
    private let disposeBag = DisposeBag()
    
    private var currentTrackId: Int?
    
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
        
        
        player.nowPlaying
            .subscribeNext { [weak self] track in
                self?.currentTrackId = track?.trackId
            }
            .addDisposableTo(disposeBag)
        
        player.currentTime
            .map(Int.init)
            .distinctUntilChanged()
            .subscribeNext { [weak self] time in
                if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo,
                    self?.currentTrackId == info["currentTrackId"] as? Int
                {
                    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    func willStartPlayTrack(_ trackId: Int) {
        guard let track = Model.Track(trackId: trackId).track else { return }
        
        print(#function, trackId)
        
        if currentTrackId == nil { currentTrackId = trackId }
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.bookmarkCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        
        let info: [String: AnyObject] = [
            MPMediaItemPropertyTitle: track.trackName,
            MPMediaItemPropertyArtist: track.artist.name,
            MPNowPlayingInfoPropertyPlaybackRate: 1,
            MPMediaItemPropertyPlaybackDuration: track.metadata.duration ?? 0,
            "currentTrackId": trackId
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        
        let size = UIScreen.main().bounds.size
        let artworkURL = track.artworkURL(size: Int(min(size.width, size.height) * UIScreen.main().scale))
        SDWebImageManager.shared().downloadImage(with: artworkURL, options: [], progress: nil, completed: { (image, error, cacheType, flag, url) in
            guard let image = image else { return }
            
            if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo, let currentTrackId = info["currentTrackId"] as? Int, currentTrackId == trackId {
                if #available(iOS 10.0, *) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: size) { size in
                        print(#function, " ", size)
                        return image
                    }
                } else {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                
                print(info)
            }
        })
    }
    
    func didEndPlay() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.bookmarkCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
    }
    
    @objc
    private func togglePlayPause() {
        guard let player = player else { return }
        if player.playing {
            pause()
        } else {
            play()
        }
    }
    @objc
    private func play() {
        player?.play()
        if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
    @objc
    private func pause() {
        player?.pause()
        if var info = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = 0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
    @objc
    private func nextTrackCommand() {
        player?.nextTrack()
        
    }
    
    @objc
    private func bookmark() {
        guard let trackId = currentTrackId else { return }
        guard let track = Model.Track(trackId: trackId).track else { return }
        
        let playlist = Model.MyPlaylist(playlist: Model.MyPlaylists()[0])
        playlist.append(track: track)
    }
//    @objc
//    private func skipBackward() {
//        
//    }
}
