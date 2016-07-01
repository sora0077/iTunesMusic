
//
//  Downloader.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/01.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift


public final class Downloader {
    
    private let disposeBag = DisposeBag()
    
    public static let instance = Downloader()
    
    private var cached: Set<PreviewTrack> = []
    
    private init() {}
    
    public func start() {
        
        History.instance.groupby
            .flatMap { [weak self] tracks in
                Observable<PreviewTrack>.create { subscriber in
                    tracks.forEach { track, _ in
                        let preview = Preview.instance.queueing(track: track)
                        if self?.cached.contains(preview) ?? false {
                            return
                        }
                        print(track.trackName)
                        self?.cached.insert(preview)
                        subscriber.onNext(preview)
                    }
                    subscriber.onCompleted()
                    return NopDisposable.instance
                }
            }
            .flatMap { preview in
                preview.download()
            }
            .subscribeNext { url, _ in
                print("cache ", url)
            }
            .addDisposableTo(disposeBag)
    }
}