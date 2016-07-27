//
//  2to3.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/27.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation


private var Locale_migrator: UInt8 = 0
extension Locale {

    final class Compatible {

        private let locale: Locale

        var countryCode: String {
            if #available(iOS 10, *) {
                return locale.countryCode
            }
            return locale.object(forKey: Locale.Key.countryCode) as! String
        }

        init(locale: Locale) {
            self.locale = locale
        }
    }

    var compatible: Compatible {
        set {
            objc_setAssociatedObject(self, &Locale_migrator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let obj = objc_getAssociatedObject(self, &Locale_migrator) as? Compatible {
                return obj
            }
            let compatible = Compatible(locale: self)
            objc_setAssociatedObject(self, &Locale_migrator, compatible, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return compatible
        }
    }

}
