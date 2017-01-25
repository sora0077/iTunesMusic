//
//  Error.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import ErrorEventHandler

extension ErrorLog {
    public typealias Error = ErrorEventHandler.Error
    public typealias Level = ErrorEventHandler.ErrorLevel
}

public enum Error: Swift.Error {
    case trackNotFound(Int)
}
