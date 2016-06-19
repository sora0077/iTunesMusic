//
//  PlayerImpl.swift
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


private class OneTrackPlaylist: PlaylistType {
    
    let changes: Observable<CollectionChange> = asObservable(Variable(.Initial))
    
    let count: Int = 1
    let isEmpty: Bool = false
    
    let objects: [Track]
    
    init(track: Track) {
        objects = [track]
    }
    
    func addInto(player player: Player) { fatalError() }
    
    subscript (index: Int) -> Track { return objects[index] }
}


final class PlayerImpl: NSObject, Player, PlayerTypeInternal {
    
    private var _playlists: ArraySlice<(PlaylistType, Int, DisposeBag)> = []
    
    private var _playingQueue: ArraySlice<Track> = []
    
    private var _previewQueue: ArraySlice<Preview> = []
    
    private let _player = AVQueuePlayer()
    
    private let _disposeBag = DisposeBag()
    
    private(set) lazy var nowPlaying: Observable<Track?> = asObservable(self._nowPlayingTrack)
    private let _nowPlayingTrack = Variable<Track?>(nil)
    
    private(set) lazy var currentTime: Observable<Float64> = asObservable(self._currentTime)
    private let _currentTime = Variable<Float64>(0)
    
    
    override init() {
        super.init()
        
//        #if TARGET_OS_SIMULATOR
            _player.volume = 0.06
//        #endif
        _player.addObserver(self, forKeyPath: "status", options: [.New, .Old], context: nil)
        _player.addObserver(self, forKeyPath: "currentItem", options: [.New, .Old], context: nil)
        
        //        _player.currentTime()
        _player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(0.1, 600), queue: nil) { [weak self] (time) in
            guard let `self` = self else { return }
            self._currentTime.value = CMTimeGetSeconds(time)
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
        case "currentItem":
            if let item = _player.currentItem {
                dispatch_async(dispatch_get_main_queue()) {
                    let realm = try! Realm()
                    let track = realm.objectForPrimaryKey(_Track.self, key: item.trackId!)!
                    self._nowPlayingTrack.value = track
                    
                }
            }
            
            print("queue state ", _player.items().count, _playlists.count, _playlists.map { $0.0.count })
            print("currentItem ", _player.currentItem)
            updatePlaylistQueue()
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
        
        if _player.items().count < 3 && !_playingQueue.isEmpty {
            
            let track = _playingQueue[_playingQueue.startIndex] as! _Track
            if let string = track._longPreviewUrl, duration = track._longPreviewDuration.value, url = NSURL(string: string) {
                
                _playingQueue = _playingQueue.dropFirst()
                
                print("now play ", track._trackName)
                
                let item = AVPlayerItem(asset: AVAsset(URL: url))
                item.trackId = track.trackId
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
                
                _player.insertItem(item, afterItem: nil)
                if _player.status == .ReadyToPlay {
                    play()
                }
            }
        }
    }
    
    private func updatePlaylistQueue() {
        
        if _player.items().count < 3 && (_playlists.reduce(0) { $0 + $1.0.count }) != 0 {
            let (playlist, index, _) = _playlists[_playlists.startIndex]
            
            let paginator = playlist as? PaginatorTypeInternal
            print(paginator, playlist)
            
            if playlist.count - index < 3 {
                paginator?.fetch()
                
                if playlist.isEmpty {
                    return
                }
            }
            print("play", playlist.count, index)
            
            if playlist.count > index {
                print("will play ", playlist[index].trackName)
                let track = playlist[index]
                _playingQueue.append(track)
                let preview = Preview(track: playlist[index])
                _playlists[_playlists.startIndex].1 += 1
                fetch(preview)
            } else {
                
                if let paginator = paginator where !paginator.hasNoPaginatedContents {
                    return
                }
                _playlists = _playlists.dropFirst()
                updatePlaylistQueue()
                print("drop playlist ", playlist)
            }
        }
        updateQueue()
    }
    
    private func fetch(preview: Preview) {
        preview.fetch()
            .subscribe(
                onNext: { [weak self] url, duration in
                    guard let `self` = self else { return }
                    self.updateQueue()
                },
                onError: { [weak self] error in
                    print(error)
                    self?.pause()
                }
            )
            .addDisposableTo(_disposeBag)
    }
    
    func add(track track: Track) {
        
        print(track.trackName)
        
        _addPlaylist(OneTrackPlaylist(track: track))
    }
    
    func addPlaylist<Playlist: PlaylistTypeInternal>(playlist: Playlist) {
        
        _addPlaylist(AnyPlaylist(playlist: playlist))
    }
    
    func addPlaylist<Playlist: protocol<PlaylistTypeInternal, PaginatorTypeInternal>>(playlist: Playlist) {
        
        _addPlaylist(AnyPaginatedPlaylist(playlist: playlist))
    }
    
    func _addPlaylist(playlist: PlaylistType) {
        
        let disposeBag = DisposeBag()
        _playlists.append((playlist, 0, disposeBag))
        updatePlaylistQueue()
        playlist.changes
            .subscribeNext { [weak self, weak playlist = playlist] changes in
                guard let `self` = self, playlist = playlist else { return }
                
                switch changes {
                case .Initial:
                    break
                case .Update(deletions: _, insertions: let insertions, modifications: _) where !insertions.isEmpty:
                    print(insertions)
                    if self._playlists.first?.0 === playlist {
                        self.updatePlaylistQueue()
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
