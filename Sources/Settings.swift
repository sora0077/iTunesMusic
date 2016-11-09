//
//  Settings.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/11/09.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation


struct Settings {
    private init() {}

    struct Track {
        private init() {}
    }
}

extension Settings.Track {
    struct Cache {
        private init() {}

        static let directory: URL = {
            let base = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            let dir = URL(fileURLWithPath: base).appendingPathComponent("tracks", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            return dir
        }()
    }
}
