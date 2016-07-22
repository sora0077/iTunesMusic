//
//  EntityTrackMetadata.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


public protocol TrackMetadata {
    
    var duration: Double? { get }
}


final class _TrackMetadata: RealmSwift.Object, TrackMetadata {
    
    dynamic var _trackId: Int = 0
    
    dynamic var _track: _Track?
    
    private dynamic var _longPreviewUrl: String?
    
    private dynamic var _longPreviewFileUrl: String?
    
    private let _longPreviewDuration: RealmOptional<Double> = RealmOptional()
    
    dynamic var _createAt: Date = Date()
    
    override class func primaryKey() -> String? { return "_trackId" }
}

extension _TrackMetadata {
    
    var previewURL: URL? {
        return _longPreviewUrl.flatMap(URL.init)
    }
    
    var fileURL: URL? {
        guard let filename = _longPreviewFileUrl else { return nil }
        
        let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        let fileURL = try! URL(fileURLWithPath: cachePath).appendingPathComponent(filename)
        if let path = fileURL.path, FileManager.default.fileExists(atPath: path) {
            return fileURL
        }
        return nil
    }
    
    var duration: Double? {
        set {
            _longPreviewDuration.value = newValue
        }
        get {
            return _longPreviewDuration.value
//            guard let duration =  else { return nil }
//            return duration / 10000
        }
    }
    
    func updatePreviewURL(_ url: URL) {
        _longPreviewUrl = url.absoluteString
    }
    
    func updateCache(filename: String) {
        _longPreviewFileUrl = filename
    }
}
