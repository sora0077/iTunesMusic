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

public final class Player: NSObject {
    
    private var _playlists: ArraySlice<(PlayerAdoptable, Int, DisposeBag)> = []

    private var _queue: ArraySlice<Preview> = []
    
    private let _player = AVQueuePlayer()
    
    private let _disposeBag = DisposeBag()
 
    public override init() {
        super.init()
        
        _player.volume = 0.06
        _player.addObserver(self, forKeyPath: "status", options: [.New, .Old], context: nil)
        _player.addObserver(self, forKeyPath: "currentItem", options: [.New, .Old], context: nil)
    }
    
    deinit {
        ["status", "currentItem"].forEach {
            _player.removeObserver(self, forKeyPath: $0)
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case "status":
            if _player.status == .ReadyToPlay {
                _player.play()
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

    public func play() {
        
        _player.play()
    }
    
    public func pause() {
        
        _player.pause()
    }
    
    private func updateQueue() {
        
        if _player.items().count < 3 && !_playlists.isEmpty {
            let (playlist, index, _) = _playlists[_playlists.startIndex]
            
//            if playlist.paginated {
            
            let paginator = playlist as? PaginatorTypeInternal
            print(paginator, playlist)
            
            if paginator?.hasNoPaginatedContents ?? false {
                _playlists = _playlists.dropFirst()
                updateQueue()
                return
            }
            if playlist.count - index < 3 {
                paginator?.fetch()
            }
            
            if playlist.count > index {
                let preview = Preview(track: playlist.track(atIndex: index))
                _playlists[_playlists.startIndex].1 += 1
                fetch(preview)
            } else if paginator == nil {
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
                    
                    print("will play \(url)")
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
                        selector: #selector(Player.didEndPlay),
                        name: AVPlayerItemDidPlayToEndTimeNotification,
                        object: item
                    )
                    
                    self._player.insertItem(item, afterItem: nil)
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
