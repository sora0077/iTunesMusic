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


extension Model {

    public final class Track: Fetchable {

        public let trackId: Int
        public var track: iTunesMusic.Track? {
            if Thread.isMainThread {
                return caches.first
            }
            let realm = iTunesRealm()
            return realm.object(ofType: _Track.self, forPrimaryKey: trackId)
        }

        private var token: NotificationToken!
        private let caches: Results<_Track>

        public convenience init(track: Track) {
            self.init(trackId: track.trackId)
        }

        public init(trackId: Int) {
            self.trackId = trackId

            let realm = iTunesRealm()
            caches = realm.allObjects(ofType: _Track.self).filter(using: "_trackId = %@", trackId)
            token = caches.addNotificationBlock { [weak self] changes in
                switch changes {
                case let .Initial(results):
                    if !results.isEmpty {
                        self?._requestState.value = .done
                    }
                case let .Update(results, deletions: _, insertions: _, modifications: _):
                    if !results.isEmpty {
                        self?._requestState.value = .done
                    }
                case .Error(let error):
                    fatalError("\(error)")
                }
            }
        }
    }
}

extension Model.Track: _Fetchable {

    var _refreshAt: Date { return caches.first?._createAt ?? Date.distantPast }

    var _refreshDuration: Duration { return 18.hours }

    func request(refreshing: Bool, force: Bool, completion: (RequestState) -> Void) {

        let lookup = LookupWithIds<LookupResponse>(id: trackId)
        Session.sharedSession.sendRequest(lookup, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            let requestState: RequestState
            defer {
                completion(requestState)
            }
            switch result {
            case .success(let response):
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
                        }
                    }
                }
                requestState = .done
            case .failure(let error):
                print(error)
                requestState = .error
            }
        }
    }
}
