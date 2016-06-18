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
import RealmSwift


private var AVPlayerItem_trackId: UInt8 = 0
private extension AVPlayerItem {
    
    var trackId: Int? {
        get {
            return objc_getAssociatedObject(self, &AVPlayerItem_trackId) as? Int
        }
        set {
            objc_setAssociatedObject(self, &AVPlayerItem_trackId, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

final class CrossFadePlayer: NSObject, PlayerTypeInternal {
    
    private var _playlists: ArraySlice<(PlaylistType, Int, DisposeBag)> = []
    
    private var _queue: ArraySlice<Preview> = []
    
    private let _player = AVQueuePlayer()
    private let _player2 = AVQueuePlayer()
    
    private let _disposeBag = DisposeBag()
    
    
    //    private
    
    
    override init() {
        super.init()
        
        _player.volume = 0.06
        _player.addObserver(self, forKeyPath: "status", options: [.New, .Old], context: nil)
        _player.addObserver(self, forKeyPath: "currentItem", options: [.New, .Old], context: nil)
        _player2.volume = 0.06
        _player2.addObserver(self, forKeyPath: "status", options: [.New, .Old], context: nil)
        _player2.addObserver(self, forKeyPath: "currentItem", options: [.New, .Old], context: nil)
        
        //        _player.currentTime()
        _player2.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.1, 600), queue: nil) { [weak self] (time) in
            guard let `self` = self else { return }
            if let currentTime = self._player2.currentItem?.duration {
                let diff = CMTimeGetSeconds(CMTimeSubtract(currentTime, time))
                print(diff)
            }
        }
    }
    
    deinit {
        ["status", "currentItem"].forEach {
            _player.removeObserver(self, forKeyPath: $0)
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case "status":
            if _player.status == .ReadyToPlay {
                _player.play()
            }
            if _player2.status == .ReadyToPlay {
                print("player2 == ReadyToPlay")
                _player2.play()
            }
        case "currentItem":
            print(_player.items().count)
            print(_player.currentItem)
            updateQueue()
            if _player.currentItem == nil {
                pause()
            }
        default:
            break
        }
    }
    
    func play() {
        
        _player.play()
    }
    
    func pause() {
        
        _player.pause()
    }
    
    private func updateQueue() {
        
        if _player.items().count < 3 && !_playlists.isEmpty {
            let (playlist, index, _) = _playlists[_playlists.startIndex]
            
            //            if playlist.paginated {
            
            let paginator = playlist as? PaginatorTypeInternal
            print(paginator, playlist)
            
            if playlist.count - index < 3 {
                paginator?.fetch()
                
                if playlist.isEmpty {
                    return
                }
            }
            print("play", playlist.count)
            
            if playlist.count > index {
                let preview = Preview(track: playlist[index])
                _playlists[_playlists.startIndex].1 += 1
                fetch(preview)
            } else if let paginator = paginator where paginator.hasNoPaginatedContents {
                _playlists = _playlists.dropFirst()
                updateQueue()
                return
            } else {
                
                _playlists = _playlists.dropFirst()
                updateQueue()
            }
        }
    }
    
    private func fetch(preview: Preview) {
        preview.fetch()
            .subscribe(
                onNext: { [weak self] url, duration in
                    guard let `self` = self else { return }
                    
                    let item = AVPlayerItem(asset: AVAsset(URL: url))
                    item.trackId = preview.id
                    if let track = item.asset.tracksWithMediaType(AVMediaTypeAudio).first {
                        let inputParams = AVMutableAudioMixInputParameters(track: track)
                        
                        let fadeDuration = CMTimeMakeWithSeconds(5, 600);
                        let fadeOutStartTime = CMTimeMakeWithSeconds(Double(duration)/10000 - 5, 600);
                        let fadeInStartTime = CMTimeMakeWithSeconds(0, 600);
                        
                        inputParams.setVolumeRampFromStartVolume(1, toEndVolume: 0, timeRange: CMTimeRangeMake(fadeOutStartTime, fadeDuration))
                        inputParams.setVolumeRampFromStartVolume(0, toEndVolume: 1, timeRange: CMTimeRangeMake(fadeInStartTime, fadeDuration))
                        
                        let audioMix = AVMutableAudioMix()
                        audioMix.inputParameters = [inputParams]
                        item.audioMix = audioMix
                    }
                    NSNotificationCenter.defaultCenter().addObserver(
                        self,
                        selector: #selector(self.didEndPlay),
                        name: AVPlayerItemDidPlayToEndTimeNotification,
                        object: item
                    )
                    
                    self._player.insertItem(item, afterItem: nil)
                    let when = { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * Double(NSEC_PER_SEC))) }
                    dispatch_after(when(1), dispatch_get_main_queue()) {
                        print("fetch player2")
                        self._player2.insertItem(AVPlayerItem(asset: AVAsset(URL: url)), afterItem: nil)
                        
                    }
                },
                onError: { [weak self] error in
                    print(error)
                    self?.pause()
                }
            )
            .addDisposableTo(_disposeBag)
    }
    
    func addPlaylist<Playlist: PlaylistTypeInternal>(playlist: Playlist) {
        
        let playlist = AnyPlaylist(playlist: playlist)
        let disposeBag = DisposeBag()
        _playlists.append((playlist, 0, disposeBag))
        updateQueue()
        playlist.changes
            .subscribeNext { [weak self, weak playlist = playlist] changes in
                guard let `self` = self, playlist = playlist else { return }
                
                switch changes {
                case .Initial:
                    break
                case .Update(deletions: _, insertions: let insertions, modifications: _) where !insertions.isEmpty:
                    if self._playlists.first?.0 === playlist {
                        self.updateQueue()
                    }
                default:
                    break
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    func addPlaylist<Playlist: protocol<PlaylistTypeInternal, PaginatorTypeInternal>>(playlist: Playlist) {
        
        let playlist = AnyPaginatedPlaylist(playlist: playlist)
        let disposeBag = DisposeBag()
        _playlists.append((playlist, 0, disposeBag))
        updateQueue()
        playlist.changes
            .subscribeNext { [weak self, weak playlist = playlist] changes in
                guard let `self` = self, playlist = playlist else { return }
                
                switch changes {
                case .Initial:
                    break
                case .Update(deletions: _, insertions: let insertions, modifications: _) where !insertions.isEmpty:
                    print(insertions)
                    if self._playlists.first?.0 === playlist {
                        self.updateQueue()
                    }
                default:
                    break
                }
            }
            .addDisposableTo(disposeBag)
    }
    
    @objc
    private func didEndPlay(notification: NSNotification) {
        
        if let item = notification.object as? AVPlayerItem, trackId = item.trackId {
            let realm = try! Realm()
            if let track = realm.objectForPrimaryKey(_Track.self, key: trackId) {
                History.add(track, realm: realm)
            }
        }
        if _player.items().count == 1 {
            pause()
        }
    }
}
