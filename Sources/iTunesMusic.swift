//
//  iTunesMusic.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/07.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import Himotoki
import RxSwift


public let player: Player = PlayerImpl()

func launch() {
    
    player.install(middleware: Model.History.instance)
    player.install(middleware: Downloader())
}
