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


func action(_ handler: ((ErrorEventHandler.Error.Type, AppErrorLevel) -> Void)?,
            error: AppError.Type = CommonError.self,
            level: AppErrorLevel = .alert) {
    handler?(error, level)
}

final class ErrorHandlingSettings {
    private static let disposeBag = DisposeBag()
    static func launch() {
        ErrorLog.event
            .drive(onNext: { error in
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
            })
            .addDisposableTo(disposeBag)
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
    case let error as NSError:
        return (error.localizedRecoverySuggestion ?? "エラー", error.localizedFailureReason ?? error.localizedDescription)
    default:
        print(error)
        return ("エラー", "不明なエラー")
    }
}

enum AppErrorLevel: ErrorEventHandler.ErrorLevel {
    case slirent, alert
}