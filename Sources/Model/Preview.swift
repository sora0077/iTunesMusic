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


final class Preview {

    fileprivate let cache = NSCache<NSString, PreviewTrack>()

    subscript (track track: Track) -> PreviewTrack? {
        set {
            cache.setObject(PreviewTrack(track: track), forKey: "\(track.id)" as NSString)
        }
        get {
            return cache.object(forKey: "\(track.id)" as NSString)
        }
    }

    func queueing(track: Track) -> PreviewTrack {
        if let previewTrack = self[track: track] {
            return previewTrack
        }
        let previewTrack = PreviewTrack(track: track)
        cache.setObject(previewTrack, forKey: "\(track.id)" as NSString)
        return previewTrack
    }
}


final class PreviewTrack {

    let id: Int
    let url: URL

    fileprivate init(track: Track) {
        id = track.id
        url = track.viewURL
    }
    func download() -> Observable<(URL, duration: Double)> {
        let id = self.id

        return fetch()
            .flatMap { url, duration -> Observable<(URL, duration: Double)> in
                if url.isFileURL {
                    return Observable.just((url, duration))
                }
                return Observable.create { subscriber in
                    let filename = url.lastPathComponent

                    let task = URLSession.shared.downloadTask(with: url, completionHandler: { (url, response, error) in
                        if let src = url {
                            let to = Model.DiskCache.shared.dir.appendingPathComponent(filename)
                            do {
                                try FileManager.default.moveItem(at: src, to: to)
                            } catch {
                                subscriber.onError(error)
                                return
                            }

                            let realm = iTunesRealm()
                            let track = realm.object(ofType: _Track.self, forPrimaryKey: id)!
                            try? realm.write {
                                let metadata = _TrackMetadata(track: track)
                                metadata.updateCache(filename: filename)
                                metadata.duration = duration
                                realm.add(metadata, update: true)
                            }
                            subscriber.onNext((to, duration))
                            subscriber.onCompleted()
                        } else {
                            subscriber.onError(error!)
                        }
                    })
                    task.resume()
                    return Disposables.create {
                        task.cancel()
                    }
                }
            }
    }

    func fetch() -> Observable<(URL, duration: Double)> {
        let id = self.id
        let url = self.url

        let realm = iTunesRealm()
        if let track = realm.object(ofType: _Track.self, forPrimaryKey: id) {
            if let duration = track.metadata?.duration {
                if let fileURL = track.metadata?.fileURL {
                    return .just((fileURL, duration))
                }
                if let url = track.metadata?.previewURL {
                    return .just((url, duration))
                }
            }
        }
        return Observable.create { subscriber in
            let task = Session.shared.send(GetPreviewUrl(id: id, url: url), callbackQueue: callbackQueue) { result in
                switch result {
                case .success(let (url, duration)):
                    let duration = Double(duration) / 1000
                    let realm = iTunesRealm()
                    try? realm.write {
                        guard let track = realm.object(ofType: _Track.self, forPrimaryKey: id) else { return }
                        let metadata = _TrackMetadata(track: track)
                        metadata.updatePreviewURL(url)
                        metadata.duration = duration
                        realm.add(metadata, update: true)
                    }
                    subscriber.onNext((url, duration))
                    subscriber.onCompleted()
                case .failure(let error):
                    subscriber.onError(error)
                }
            }
            return Disposables.create {
                task?.cancel()
            }
        }
    }
}

extension PreviewTrack: Equatable, Hashable {

    var hashValue: Int { return id }
}

func == (lhs: PreviewTrack, rhs: PreviewTrack) -> Bool {
    return lhs.id == rhs.id
}
