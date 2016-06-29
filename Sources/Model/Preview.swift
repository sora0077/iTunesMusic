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


public final class Preview {
    
    let id: Int
    let url: NSURL
    
    var duration: Int = 0
    
    public init(track: Track) {
        let track = track as! _Track
        id = track.trackId
        url = track.trackViewURL
    }
    
    public func download() -> Observable<(NSURL, duration: Int)> {
        let id = self.id
        return fetch()
            .flatMap { url, duration -> Observable<(NSURL, duration: Int)> in
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
                            
                            let realm = try! Realm()
                            let track = realm.objectForPrimaryKey(_Track.self, key: id)!
                            try! realm.write {
                                track._longPreviewFileUrl = to.path
                                track._longPreviewDuration.value = duration
                            }
                            subscriber.onNext((to, track._longPreviewDuration.value!))
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
    
    func fetch() -> Observable<(NSURL, duration: Int)> {
        let id = self.id
        let url = self.url
        
        let realm = try! Realm()
        if let track = realm.objectForPrimaryKey(_Track.self, key: id), duration = track._longPreviewDuration.value {
            if let path = track._longPreviewFileUrl {
                if NSFileManager.defaultManager().fileExistsAtPath(path) {
                    print("file exists")
                    return Observable.just((NSURL(fileURLWithPath: path), duration))
                }
            }
            if let string = track._longPreviewUrl, url = NSURL(string: string) {
                return Observable.just((url, duration))
            }
        }
        
        let session = Session(adapter: NSURLSessionAdapter(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()))
        
        return Observable.create { [weak self] subscriber in
            let task = session.sendRequest(GetPreviewUrl(id: id,  url: url)) { result in
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    switch result {
                    case .Success(let (url, duration)):
                        self?.duration = duration
                        let realm = try! Realm()
                        try! realm.write {
                            guard let track = realm.objectForPrimaryKey(_Track.self, key: id) else { return }
                            track._longPreviewUrl = url.absoluteString
                            track._longPreviewDuration.value = duration
                        }
                        subscriber.onNext((url, duration))
                        subscriber.onCompleted()
                    case .Failure(let error):
                        subscriber.onError(error)
                    }
                }
            }
            return AnonymousDisposable {
                task?.cancel()
            }
        }
    }
    
}