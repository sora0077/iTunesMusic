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
    
    private var changes: Observable<CollectionChange> = asObservable(Variable(.initial))
    
    private var count: Int { return objects.count }
    
    private var isEmpty: Bool { return objects.isEmpty }
    
    subscript (index: Int) -> Track { return objects[index] }
    
    private let objects: [Track]
    
    init(track: Track) { objects = [track] }
}

final class PlayerImpl: NSObject, Player {
    
    var playlists: [PlaylistType] { return _playlists.map { $0.0 } }
    
    private var _playlists: ArraySlice<(PlaylistType, Int, DisposeBag)> = []
    
    private var _playingQueue: ArraySlice<Track> = []
    
    private var _previewQueue: [Int: PreviewTrack] = [:]
    
    private let _player = AVQueuePlayer()
    
    private let _disposeBag = DisposeBag()
    
    private(set) lazy var nowPlaying: Observable<Track?> = asObservable(self._nowPlayingTrack)
    private let _nowPlayingTrack = Variable<Track?>(nil)
    
    private(set) lazy var currentTime: Observable<Float64> = asObservable(self._currentTime)
    private let _currentTime = Variable<Float64>(0)
    
    private var _installs: [PlayerMiddleware] = []
    
    override init() {
        super.init()
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            _player.volume = 0.02
            print("simulator")
        #else
            print("iphone")
        #endif
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
    
    func install(middleware middleware: PlayerMiddleware) {
        _installs.append(middleware)
    }
    
    func play() { _player.play() }
    
    func pause() { _player.pause() }
    
    private func updateQueue() {
        
        print("caller updateQueue")
        
        if !(_player.items().count < 3 && !_playingQueue.isEmpty) {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            print("run updateQueue")
            let track = self._playingQueue[self._playingQueue.startIndex] as! _Track
            func getPreviewInfo() -> (NSURL, duration: Int)? {
                guard let duration = track._longPreviewDuration.value else { return nil }
                
                if let path = track._longPreviewFileUrl where NSFileManager.defaultManager().fileExistsAtPath(path) {
                    return (NSURL(fileURLWithPath: path), duration)
                }
                if let string = track._longPreviewUrl, url = NSURL(string: string) {
                    return (url, duration)
                }
                return nil
            }
            if let (url, duration) = getPreviewInfo() {
                
                self._playingQueue = self._playingQueue.dropFirst()
                
                print("add player queue ", track._trackName, url)
                let item = AVPlayerItem(asset: AVAsset(URL: url))
                item.trackId = track.trackId
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    
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
                    if self._player.status == .ReadyToPlay {
                        self.play()
                    }
                }
            } else {
                self.fetch(Preview.instance.queueing(track: track))
            }
        }
    }
    
    private func updatePlaylistQueue() {
        defer {
            updateQueue()
        }
        if !(_player.items().count < 3 && !_playlists.isEmpty) {
            return
        }
        
        let (playlist, index, _) = _playlists[_playlists.startIndex]
        
        let paginator = playlist as? FetchableInternal
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
            _playlists[_playlists.startIndex].1 += 1
            updateQueue()
        } else {
            
            if let paginator = paginator where !paginator.hasNoPaginatedContents {
                return
            }
            _playlists = _playlists.dropFirst()
            updatePlaylistQueue()
            print("drop playlist ", playlist)
        }
    }
    
    private func fetch(preview: PreviewTrack) {
        let id = preview.id
        if _previewQueue[id] != nil {
            return
        }
        _previewQueue[id] = preview
        
        preview.fetch()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] url in
                    guard let `self` = self else { return }
                    self._previewQueue[id] = nil
                    self.updateQueue()
                },
                onError: { [weak self] error in
                    guard let `self` = self else { return }
                    self._previewQueue[id] = nil
                    self._playingQueue = ArraySlice(self._playingQueue.filter { $0.trackId != id })
                    self.updatePlaylistQueue()
                }
            )
            .addDisposableTo(_disposeBag)
    }
    
    
    func add(track track: Track) {
        add(track: track, afterPlaylist: false)
    }
    
    func add(track track: Track, afterPlaylist: Bool) {
        if afterPlaylist {
            add(playlist: OneTrackPlaylist(track: track))
        } else {
            _playingQueue.append(track)
            updateQueue()
        }
    }
    
    func add(playlist playlist: PlaylistType) {
        
        _add(playlist: playlist)
    }
    
    private func _add(playlist playlist: PlaylistType) {
        
        assert(NSThread.isMainThread())
        
        if _player.status == .ReadyToPlay && _player.rate != 0 {
            play()
        }
        
        let disposeBag = DisposeBag()
        _playlists.append((playlist, 0, disposeBag))
        updatePlaylistQueue()
        playlist.changes
            .subscribe(
                onNext: { [weak self, weak playlist = playlist] changes in
                    guard let `self` = self, playlist = playlist else { return }
                    
                    switch changes {
                    case .update(deletions: _, insertions: let insertions, modifications: _) where !insertions.isEmpty:
                        print(insertions)
                        if self._playlists.first?.0 === playlist {
                            self.updatePlaylistQueue()
                        }
                    default:
                        break
                    }
                },
                onDisposed: { [weak playlist] in
                    print("disposed ", playlist)
                }
            )
            .addDisposableTo(disposeBag)
    }
    
    @objc
    private func didEndPlay(notification: NSNotification) {
        
        if let item = notification.object as? AVPlayerItem, trackId = item.trackId {
            _installs.forEach { $0.didEndPlayTrack(trackId) }
        }
        if _player.items().count == 1 {
            pause()
        }
    }
}
