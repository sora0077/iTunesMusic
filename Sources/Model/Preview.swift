//
//  Preview.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import RealmSwift
import RxSwift
import AVKit
import AVFoundation
import PINCache


final class Preview {
    
    private let cache = NSCache()
    
    static let instance = Preview()
    
    private init() {}

    subscript (track track: Track) -> PreviewTrack? {
        set {
            cache.setObject(PreviewTrack(track: track), forKey: track.trackId)
        }
        get {
            return cache.objectForKey(track.trackId) as? PreviewTrack
        }
    }
    
    func queueing(track track: Track) -> PreviewTrack {
        if let previewTrack = self[track: track] {
            return previewTrack
        }
        let previewTrack = PreviewTrack(track: track)
        cache.setObject(previewTrack, forKey: track.trackId)
        return previewTrack
    }
}


final class PreviewTrack {
    
    let id: Int
    let url: NSURL
    
    private init(track: Track) {
        let track = track as! _Track
        id = track.trackId
        url = track.trackViewURL
    }
    func download() -> Observable<(NSURL, duration: Double)> {
        let id = self.id
    
        return fetch()
            .flatMap { url, duration -> Observable<(NSURL, duration: Double)> in
                if url.fileURL {
                    return Observable.just((url, duration))
                }
                return Observable.create { subscriber in
                    let session = NSURLSession.sharedSession()
                    let filename = url.lastPathComponent!
                    
                    let task = session.downloadTaskWithURL(url, completionHandler: { (url, response, error) in
                        if let src = url {
                            let path = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
                            let to = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(filename)
                            _ = try? NSFileManager.defaultManager().moveItemAtURL(src, toURL: to)
                            
                            let realm = try! iTunesRealm()
                            let track = realm.objectForPrimaryKey(_Track.self, key: id)!
                            try! realm.write {
                                track._metadata.updateCache(filename: filename)
                                track._metadata.duration = duration
                                realm.add(track._metadata, update: true)
                            }
                            subscriber.onNext((to, duration))
                            subscriber.onCompleted()
                        } else {
                            subscriber.onError(error!)
                        }
                    })
                    task.resume()
                    return AnonymousDisposable {
                        task.cancel()
                    }
                }
            }
    }
    
    func fetch() -> Observable<(NSURL, duration: Double)> {
        let id = self.id
        let url = self.url
        
        let realm = try! iTunesRealm()
        if let track = realm.objectForPrimaryKey(_Track.self, key: id) where track.hasMetadata {
            if let duration = track.metadata.duration {
                if let fileURL = track._metadata.fileURL {
                    return Observable.just((fileURL, duration))
                }
                if let url = track._metadata.previewURL {
                    return Observable.just((url, duration))
                }
            }
        }
        
        let session = Session.sharedSession
        
        return Observable.create { subscriber in
            let task = session.sendRequest(GetPreviewUrl(id: id,  url: url), callbackQueue: callbackQueue) { result in
                switch result {
                case .Success(let (url, duration)):
                    let duration = Double(duration) / 10000
                    let realm = try! iTunesRealm()
                    try! realm.write {
                        guard let track = realm.objectForPrimaryKey(_Track.self, key: id) else { return }
                        track._metadata.updatePreviewURL(url)
                        track._metadata.duration = duration
                        realm.add(track._metadata, update: true)
                    }
                    subscriber.onNext((url, duration))
                    subscriber.onCompleted()
                case .Failure(let error):
                    subscriber.onError(error)
                }
            }
            return AnonymousDisposable {
                task?.cancel()
            }
        }
    }
}

extension PreviewTrack: Equatable, Hashable {
    
    var hashValue: Int { return id }
}

func ==(lhs: PreviewTrack, rhs: PreviewTrack) -> Bool {
    return lhs.id == rhs.id
}