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
    
    var playing: Bool { return _player.rate != 0 }
    
    override init() {
        super.init()
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            _player.volume = 0.02
            print("simulator")
        #else
            print("iphone")
        #endif
        _player.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        _player.addObserver(self, forKeyPath: "currentItem", options: [.new, .old], context: nil)
        
        //        _player.currentTime()
        _player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, 600), queue: nil) { [weak self] (time) in
            guard let `self` = self else { return }
            self._currentTime.value = CMTimeGetSeconds(time)
        }
    }
    
    deinit {
        ["status", "currentItem"].forEach {
            _player.removeObserver(self, forKeyPath: $0)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case "status":
            if _player.status == .readyToPlay {
                _player.play()
            }
        case "currentItem":
            DispatchQueue.main.async {
                let realm = try! iTunesRealm()
                var track: Track?
                if let trackId = self._player.currentItem?.trackId {
                    track = realm.object(ofType: _Track.self, forPrimaryKey: trackId)
                }
                self._nowPlayingTrack.value = track
                
                if let trackId = self._player.currentItem?.trackId {
                    self._installs.forEach { $0.willStartPlayTrack(trackId) }
                } else {
                    self._installs.forEach { $0.didEndPlay() }
                }
                self.updatePlaylistQueue()
            }
            
            if _player.currentItem == nil {
                pause()
            }
        default:
            break
        }
    }
    
    func install(middleware: PlayerMiddleware) {
        _installs.append(middleware)
        middleware.middlewareInstalled(self)
    }
    
    func play() {
        print(_player.rate)
        _player.play()
    }
    
    func pause() { _player.pause() }
    
    func nextTrack() { _player.advanceToNextItem() }
    
    private func updateQueue() {
        
        print("caller updateQueue")
        if _playingQueue.isEmpty { return }
        
        if _player.items().count > 2 { return }
        
        DispatchQueue.main.async {
            print("run updateQueue")
            let track = self._playingQueue[self._playingQueue.startIndex] as! _Track
            if !track.canPreview {
                self._playingQueue = self._playingQueue.dropFirst()
                return self.updateQueue()
            }
            func getPreviewInfo() -> (URL, duration: Double)? {
                if !track.hasMetadata { return nil }
                guard let duration = track.metadata.duration else { return nil }
                
                if let fileURL = track._metadata.fileURL {
                    print("load from file ", track.trackName)
                    return (fileURL as URL, duration)
                }
                if let url = track._metadata.previewURL {
                    print("load from network ", track.trackName)
                    return (url as URL, duration)
                }
                return nil
            }
            if let (url, duration) = getPreviewInfo() {
                
                self._playingQueue = self._playingQueue.dropFirst()
                
                print("add player queue ", track._trackName, url)
                let item = AVPlayerItem(asset: AVAsset(url: url))
                item.trackId = track.trackId
                
                DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault).async {
                    
                    if let track = item.asset.tracks(withMediaType: AVMediaTypeAudio).first {
                        let inputParams = AVMutableAudioMixInputParameters(track: track)
                        
                        let fadeDuration = CMTimeMakeWithSeconds(5, 600);
                        let fadeOutStartTime = CMTimeMakeWithSeconds(duration - 5, 600);
                        let fadeInStartTime = CMTimeMakeWithSeconds(0, 600);
                        
                        inputParams.setVolumeRamp(fromStartVolume: 1, toEndVolume: 0, timeRange: CMTimeRangeMake(fadeOutStartTime, fadeDuration))
                        inputParams.setVolumeRamp(fromStartVolume: 0, toEndVolume: 1, timeRange: CMTimeRangeMake(fadeInStartTime, fadeDuration))
                        
                        let audioMix = AVMutableAudioMix()
                        audioMix.inputParameters = [inputParams]
                        item.audioMix = audioMix
                    }
                    NotificationCenter.default.addObserver(
                        self,
                        selector: #selector(self.didEndPlay),
                        name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                        object: item
                    )
                    
                    self._player.insert(item, after: nil)
                    if self._player.status == .readyToPlay {
                        self.play()
                    }
                }
            } else {
                self.fetch(Preview.instance.queueing(track: track))
            }
        }
    }
    
    private func updatePlaylistQueue() {
        if _playlists.isEmpty { return }
        if _player.items().count > 2 { return }
        
        let (playlist, index, _) = _playlists[_playlists.startIndex]
        assert(Thread.isMainThread)
        
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
            print(playlist)
            if let paginator = paginator, !paginator.hasNoPaginatedContents {
                return
            }
            _playlists = _playlists.dropFirst()
            updatePlaylistQueue()
            print("drop playlist ", playlist)
        }
    }
    
    private func fetch(_ preview: PreviewTrack) {
        let id = preview.id
        if _previewQueue[id] != nil {
            return
        }
        _previewQueue[id] = preview
        
        preview.fetch()
            .subscribe(
                onNext: { [weak self] url in
                    guard let `self` = self else { return }
                    DispatchQueue.main.async {
                        self._previewQueue[id] = nil
                        self.updateQueue()
                    }
                },
                onError: { [weak self] error in
                    guard let `self` = self else { return }
                    DispatchQueue.main.async {
                        self._previewQueue[id] = nil
                        self._playingQueue = ArraySlice(self._playingQueue.filter { $0.trackId != id })
                        self.updatePlaylistQueue()
                    }
                }
            )
            .addDisposableTo(_disposeBag)
    }
    
    
    func add(track: Track) {
        add(track: track, afterPlaylist: false)
    }
    
    func add(track: Track, afterPlaylist: Bool) {
        if afterPlaylist {
            add(playlist: OneTrackPlaylist(track: track))
        } else {
            _playingQueue.append(track)
            updateQueue()
        }
    }
    
    func add(playlist: PlaylistType) {
        
        _add(playlist: playlist)
    }
    
    private func _add(playlist: PlaylistType) {
        
        assert(Thread.isMainThread)
        
        if _player.status == .readyToPlay && _player.rate != 0 {
            play()
        }
        
        let disposeBag = DisposeBag()
        _playlists.append((playlist, 0, disposeBag))
        updatePlaylistQueue()
        playlist.changes
            .subscribe(
                onNext: { [weak self, weak playlist = playlist] changes in
                    guard let `self` = self, let playlist = playlist else { return }
                    
                    assert(Thread.isMainThread)
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
    private func didEndPlay(_ notification: Foundation.Notification) {
        assert(Thread.isMainThread)
        
        if let item = notification.object as? AVPlayerItem, let trackId = item.trackId {
            _installs.forEach { $0.didEndPlayTrack(trackId) }
        }
        if _player.items().count == 1 {
            pause()
        }
    }
}
