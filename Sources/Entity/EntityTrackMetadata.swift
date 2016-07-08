//
//  EntityTrackMetadata.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


final class _TrackMetadata: RealmSwift.Object {
    
    dynamic var _trackId: Int = 0
    
    dynamic var _track: _Track?
    
    private dynamic var _longPreviewUrl: String?
    
    private dynamic var _longPreviewFileUrl: String?
    
    private let _longPreviewDuration: RealmOptional<Int> = RealmOptional()
    
    dynamic var _createAt: NSDate = NSDate()
    
    override class func primaryKey() -> String? { return "_trackId" }
}

extension _TrackMetadata {
    
    var previewURL: NSURL? {
        return _longPreviewUrl.flatMap(NSURL.init)
    }
    
    var fileURL: NSURL? {
        guard let filename = _longPreviewFileUrl else { return nil }
        
        let cachePath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        let fileURL = NSURL(fileURLWithPath: cachePath).URLByAppendingPathComponent(filename)
        if let path = fileURL.path where NSFileManager.defaultManager().fileExistsAtPath(path) {
            return fileURL
        }
        return nil
    }
    
    var duration: Int? {
        set {
            _longPreviewDuration.value = newValue
        }
        get {
            return _longPreviewDuration.value
        }
    }
    
    func updatePreviewURL(url: NSURL) {
        _longPreviewUrl = url.absoluteString
    }
    
    func updateCache(filename filename: String) {
        _longPreviewFileUrl = filename
    }
}
