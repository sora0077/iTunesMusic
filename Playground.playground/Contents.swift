//: Playground - noun: a place where people can play

import UIKit
import iTunesMusic
import APIKit
import RealmSwift
import XCPlayground

let when = { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * Double(NSEC_PER_SEC))) }

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

let history = History.instance
history.changes.subscribe { changes in
    print("first", changes)
}

for h in history {
    
}

iTunesMusic.player
let search = Search(term: "シンフォギア ")

search.addInto(player: player)
history.addInto(player: player)
//if search.isEmp