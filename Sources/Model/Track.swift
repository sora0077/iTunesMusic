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


extension Model {

    public final class Track: Fetchable, _Fetchable {

        public let trackId: Int
        public var track: iTunesMusic.Track? {
            let realm = iTunesRealm()
            return realm.object(ofType: _Track.self, forPrimaryKey: trackId)
        }

        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)

        private var token: NotificationToken!

        private(set) var needRefresh: Bool = true

        public init(trackId: Int) {
            self.trackId = trackId

            let realm = iTunesRealm()
            token = realm.allObjects(ofType: _Track.self).filter(using: "_trackId = %@", trackId).addNotificationBlock { [weak self] changes in
                switch changes {
                case let .Initial(results):
                    self?.needRefresh = results.isEmpty
                    if !results.isEmpty {
                        self?._requestState.value = .done
                    }
                case let .Update(results, deletions: _, insertions: _, modifications: _):
                    self?.needRefresh = results.isEmpty
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

extension Model.Track {


    func request(refreshing: Bool, force: Bool) {

        let session = Session.sharedSession

        var lookup = LookupWithIds<LookupResponse>(id: trackId)
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            defer {
                tick()
            }
            switch result {
            case .success(let response):
                let realm = iTunesRealm()
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
                    self._requestState.value = .done
                }
            case .failure(let error):
                print(error)
                self._requestState.value = .error
            }
        }
    }
}
