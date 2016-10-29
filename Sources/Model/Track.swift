//
//  Track.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/14.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import RxSwift
import APIKit
import RealmSwift
import Timepiece
import ErrorEventHandler


extension Model {

    public final class Track: Fetchable {

        public let trackId: Int
        public var entity: iTunesMusic.Track? {
            if Thread.isMainThread {
                return caches.first
            }
            let realm = iTunesRealm()
            return realm.object(ofType: _Track.self, forPrimaryKey: trackId)
        }

        private var token: NotificationToken!
        fileprivate let caches: Results<_Track>

        public convenience init(track: iTunesMusic.Track) {
            self.init(trackId: track.id)
        }

        public init(trackId: Int) {
            self.trackId = trackId

            let realm = iTunesRealm()
            caches = realm.objects(_Track.self).filter("_trackId = %@", trackId)
            token = caches.addNotificationBlock { [weak self] changes in
                switch changes {
                case let .initial(results):
                    if !results.isEmpty {
                        self?._requestState.value = .done
                    }
                case let .update(results, deletions: _, insertions: _, modifications: _):
                    if !results.isEmpty {
                        self?._requestState.value = .done
                    }
                case .error(let error):
                    fatalError("\(error)")
                }
            }
        }
    }
}

extension Model.Track: _Fetchable {

    var _refreshAt: Date { return caches.first?._createAt ?? Date.distantPast }

    var _refreshDuration: Duration { return 18.hours }
}

extension Model.Track: _FetchableSimple {

    typealias Request = LookupWithIds<LookupResponse>

    func makeRequest(refreshing: Bool) -> Request? {
        return LookupWithIds(id: trackId)
    }

    func doResponse(_ response: Request.Response, request: Request, refreshing: Bool) -> RequestState {
        if response.objects.isEmpty {
            return .error(Error.trackNotFound(trackId))
        }
        let realm = iTunesRealm()
        // swiftlint:disable force_try
        try! realm.write {
            response.objects.reversed().forEach {
                switch $0 {
                case .track(let obj):
                    realm.add(obj, update: true)
                case .collection(let obj):
                    realm.add(obj, update: true)
                case .artist(let obj):
                    realm.add(obj, update: true)
                case .unknown:()
                }
            }
        }
        return .done
    }
}
