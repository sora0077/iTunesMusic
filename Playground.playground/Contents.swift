//: Playground - noun: a place where people can play

import UIKit
@testable import iTunesMusic
import APIKit
import RealmSwift
import XCPlayground

let when = { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * Double(NSEC_PER_SEC))) }

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
