//
//  MyPlaylistCache.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/16.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RealmSwift


final class _MyPlaylistCache: _Cache {

    let playlists = List<_MyPlaylist>()
}
