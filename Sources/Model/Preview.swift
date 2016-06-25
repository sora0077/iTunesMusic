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
    
    let id: Int
    let url: NSURL
    
    var duration: Int = 0
    
    init(track: Track) {
        let track = track as! _Track
        id = track.trackId
        url = track.trackViewURL
    }
    
//    func download() -> Observable<NSURL> {
//        return fetch()
//            .flatMap { url in
//                Observable<(NSURL, NSURL?)>.create { subscriber in
//                    PINCache.sharedCache().diskCache.fileURLForKey(url.absoluteString, block: { (cache, key, data, fileURL) in
//                        
//                        subscriber.onNext((url, fileURL))
//                        subscriber.onCompleted()
//                    })
//                    return NopDisposable.instance
//                }
//            }
//            .flatMap { url, fileURL -> Observable<NSURL> in
//                if let fileURL = fileURL {
//                    return Observable.just(fileURL)
//                } else {
//                    let session = NSURLSession.sharedSession()
//                    return Observable.create { subscriber in
//                        
//                        let task = session.dataTaskWithRequest(NSURLRequest(URL: url), completionHandler: { (data, response, error) in
//                            if let data = data {
//                                PINCache.sharedCache().setObject(data, forKey: url.absoluteString)
//                                PINCache.sharedCache().diskCache.fileURLForKey(url.absoluteString, block: { (cache, key, data, fileURL) in
//                                    subscriber.onNext(fileURL!)
//                                    subscriber.onCompleted()
//                                    print(fileURL)
//                                })
//                            } else {
//                                subscriber.onError(iTunesMusicError.NotFound)
//                            }
//                        })
//                        task.resume()
//                        return AnonymousDisposable {
//                            task.cancel()
//                        }
//                    }
//                }
//            }
//    }
    
    func fetch() -> Observable<(NSURL, duration: Int)> {
        let id = self.id
        let url = self.url
        
        let realm = try! Realm()
        if
            let track = realm.objectForPrimaryKey(_Track.self, key: id),
            let string = track._longPreviewUrl, url = NSURL(string: string),
            let duration = track._longPreviewDuration.value {
            return Observable.just((url, duration))
        }
        
        let session = Session(adapter: NSURLSessionAdapter(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()))
        
        return Observable.create { [weak self] subscriber in
            let task = session.sendRequest(GetPreviewUrl(id: id,  url: url)) { result in
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
            return AnonymousDisposable {
                task?.cancel()
            }
        }
    }
    
}