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
    
    func middlewareInstalled(player: Player) {
        self.player = player
        
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()
        commandCenter.togglePlayPauseCommand.addTarget(self, action: #selector(self.togglePlayPause))
        commandCenter.togglePlayPauseCommand.enabled = true
        commandCenter.playCommand.addTarget(self, action: #selector(self.play))
        commandCenter.playCommand.enabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(self.pause))
        commandCenter.pauseCommand.enabled = true
        commandCenter.nextTrackCommand.addTarget(self, action: #selector(self.nextTrackCommand))
        commandCenter.nextTrackCommand.enabled = true
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
            .subscribeNext { time in
                if var info = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
                    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
                    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    func willStartPlayTrack(trackId: Int) {
        guard let track = Model.Track(trackId: trackId).track else { return }
        
        print(#function)
        
        if currentTrackId == nil { currentTrackId = trackId }
        
        var info: [String: AnyObject] = [
            MPMediaItemPropertyTitle: track.trackName,
            MPMediaItemPropertyArtist: track.artist.name,
            MPNowPlayingInfoPropertyPlaybackRate: 1,
            MPMediaItemPropertyPlaybackDuration: track.metadata.duration ?? 0
        ]
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
        
        let size = UIScreen.mainScreen().bounds.size
        let artworkURL = track.artworkURL(size: Int(min(size.width, size.height) * UIScreen.mainScreen().scale))
        SDWebImageManager.sharedManager().downloadImageWithURL(artworkURL, options: [], progress: nil, completed: { [weak self] (image, error, cacheType, flag, url) in
            guard let image = image else { return }
            
            if self?.currentTrackId == trackId {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
                
                print(info)
            }
        })
    }
    
    func didEndPlay() {
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
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
        if var info = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
        }
    }
    @objc
    private func pause() {
        player?.pause()
        if var info = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = 0
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
        }
    }
    @objc
    private func nextTrackCommand() {
        player?.nextTrack()
        
    }
//    @objc
//    private func skipBackward() {
//        
//    }
}