//
//  Action.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/09/15.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import ErrorEventHandler


extension UIAlertController {

    static func alertController(with event: ErrorLog.Event) -> UIAlertController {
        let alert = UIAlertController(
            title: (event.error as? AppError)?.title,
            message: (event.error as? AppError)?.message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            event.resolved()
        }))

        return alert
    }
}

protocol AppError: ErrorLog.Error {
    var title: String { get }
    var message: String? { get }
}

extension AppError {

    var message: String? { return nil }
}

enum CommonError: AppError {
    case none, error(Swift.Error)

    init(error: Swift.Error?) {
        self = error.map(CommonError.error) ?? .none
    }

    var title: String {
        return "エラー"
    }

    #if DEBUG
    var message: String? {
        switch self {
        case .none:
            return "不明なエラー"
        case .error(let error):
            return "\(error)"
        }
    }
    #endif
}

enum AppErrorLevel: ErrorEventHandler.ErrorLevel {
    case slirent, alert
}

func action(_ handler: ((ErrorEventHandler.Error.Type, AppErrorLevel) -> Void)?,
            error: AppError.Type = CommonError.self,
            level: AppErrorLevel = .alert) {
    handler?(error, level)
}
