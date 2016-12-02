//
//  ErrorHandling.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/08.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import ErrorEventHandler
import RxSwift
import enum APIKit.SessionTaskError
import enum iTunesMusic.Error


protocol AppError: ErrorLog.Error {
    var title: String { get }
    var message: String? { get }
}

extension AppError {

    var message: String? { return nil }
}

enum CommonError: AppError {
    case none, error(Swift.Error)

    private var error: Swift.Error? {
        switch self {
        case .error(let error):
            return error
        case .none:
            return nil
        }
    }

    init(error: Swift.Error?) {
        self = error.map(CommonError.error) ?? .none
    }

    var title: String {
        return errorDescription(from: error).0
    }

    var message: String? {
        return errorDescription(from: error).1
    }
}


func partial<A, B, R>(_ f: @escaping (A, B) -> R, _ val: @escaping @autoclosure () -> A) -> (B) -> R {
    return { f(val(), $0) }
}


func partial<A, B, C, R>(_ f: @escaping (A, B, C) -> R, _ val: @escaping @autoclosure () -> A) -> (B, C) -> R {
    return { f(val(), $0, $1) }
}


func action(_ handler: (((ErrorEventHandler.Error.Type, AppErrorLevel) -> Void)?),
            error: AppError.Type = CommonError.self,
            level: AppErrorLevel = .alert) {
    handler?(error, level)
}


final class ErrorHandlingSettings {
    static func launch() {
        ErrorLog.observe { error in
            print(error)
            switch error.level {
            case let level as AppErrorLevel:
                switch level {
                case .alert:
                    let root = errorManageViewController()
                    let presented = root.presentedViewController ?? root
                    let alert = UIAlertController.alertController(with: error)
                    presented.present(alert, animated: true, completion: nil)
                case .slirent:
                    break
                }
            default:
                break
            }
        }
    }
}


extension UIAlertController {

    fileprivate static func alertController(with event: ErrorLog.Event) -> Self {
        let alert = self.init(
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


private func errorDescription(from error: Swift.Error?) -> (String, String) {
    switch error {
    case let error as SessionTaskError:
        return errorDescription(from: {
            switch error {
            case .connectionError(let error): return error
            case .requestError(let error): return error
            case .responseError(let error): return error
            }
            }())
    case let error as iTunesMusic.Error:
        switch error {
        case .trackNotFound(let trackId):
            return ("エラー", "指定された曲は存在しません :\(trackId)")
        }
    case _ as RealmError:
        return ("エラー", "致命的なエラーが発生したためデータベースを初期化しました")
    case let error as NSError:
        return (error.localizedRecoverySuggestion ?? "エラー", error.localizedFailureReason ?? error.localizedDescription)
    default:
        return ("エラー", "不明なエラー")
    }
}


enum AppErrorLevel: ErrorEventHandler.ErrorLevel {
    case slirent, alert
}
