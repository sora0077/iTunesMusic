//
//  2to3.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/27.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation


extension Locale {

    final class Compatible {

        // swiftlint:disable nesting
        private struct Key {
            static var countryCode: UInt8 = 0
        }

        private let locale: Locale

        var countryCode: String {
            if #available(iOS 10, *) {
                return locale.countryCode
            }
            // swiftlint:disable force_cast
            return locale.object(forKey: Locale.Key.countryCode) as! String
        }

        init(locale: Locale) {
            self.locale = locale
        }
    }

    var compatible: Compatible {
        if let obj = objc_getAssociatedObject(self, &Compatible.Key.countryCode) as? Compatible {
            return obj
        }
        let compatible = Compatible(locale: self)
        objc_setAssociatedObject(self, &Compatible.Key.countryCode, compatible, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return compatible
    }

}
