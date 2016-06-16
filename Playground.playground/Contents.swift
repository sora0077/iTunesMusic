//: Playground - noun: a place where people can play

import UIKit
@testable import iTunesMusic
import APIKit
import RealmSwift
import XCPlayground

let when = { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * Double(NSEC_PER_SEC))) }



XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

let history = History.instance
history.changes.subscribe { changes in
    print("first", changes)
}

let player = Player()
let search = Search(term: "シンフォギア")
player.addPlaylist(his)
//if search.isEmpty {
//    search.fetch()
//    search.changes.subscribeNext { changes in
//        print("1", changes)
//    }
//    
//} else {
//    print(search.count)
//    
//    player.addPlaylist(search)
//
//    player.play()
//}


