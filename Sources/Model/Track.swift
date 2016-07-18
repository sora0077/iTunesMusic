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
    
    public final class Track: Fetchable, FetchableInternal {
        
        public let trackId: Int
        public var track: iTunesMusic.Track? {
            let realm = try! iTunesRealm()
            return realm.objectForPrimaryKey(_Track.self, key: trackId)
        }
        
        public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
        private(set) var _requestState = Variable<RequestState>(.none)
        
        private var token: NotificationToken!
        
        private(set) var needRefresh: Bool = true
        
        public init(trackId: Int) {
            self.trackId = trackId
            
            let realm = try! iTunesRealm()
            token = realm.objects(_Track).filter("_trackId = %@", trackId).addNotificationBlock { [weak self] changes in
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
    
    
    func request(refreshing refreshing: Bool, force: Bool) {
        
        let session = Session.sharedSession
        
        var lookup = LookupWithIds<LookupResponse>(id: trackId)
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup, callbackQueue: callbackQueue) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .Success(let response):
                let realm = try! iTunesRealm()
                try! realm.write {
                    response.objects.reverse().forEach {
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
                tick()
            case .Failure(let error):
                print(error)
                self._requestState.value = .error
            }
        }
    }
}