//
//  Rss.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import APIKit
import RxSwift
import RealmSwift


public final class Rss: Fetchable, FetchableInternal {
    
    public private(set) lazy var requestState: Observable<RequestState> = asObservable(self._requestState)
    private(set) var _requestState = Variable<RequestState>(.none)
    
    private let id: Int
    private let url: NSURL
    
    private var trackIds: [Int] = [] {
        didSet {
            index = 0
        }
    }
    private var index = 0
    
    public init(genre: Genre) {
        id = genre.id
        url = genre.rssUrls.topSongs
     
        let realm = try! Realm()
        if let feed = realm.objectForPrimaryKey(_RssFeed.self, key: id) {
            trackIds = feed.items.map { $0.id }
        }
        
    }
    
    func request(refreshing refreshing: Bool) {
        if trackIds.isEmpty || refreshing {
            fetchFeed()
            return
        }
        
        let session = Session.sharedSession
        let id = self.id
        let ids = trackIds[index..<(index+10)]
        var lookup = LookupWithIds<LookupResultPage>(ids: Array(ids))
        lookup.lang = "ja_JP"
        lookup.country = "JP"
        session.sendRequest(lookup) { [weak self] result in
            switch result {
            case .Success(let response):
                let realm = try! Realm()
                try! realm.write {
                    realm.add(response.objects, update: true)
                    
                    if let feed = realm.objects(_RssFeed).filter("_genre._id == \(id)").first {
                        feed.tracks.appendContentsOf(response.objects)
                        self?.index += 10
                        print(feed)
                    }
                }
            case .Failure(let error):
                print(error)
            }
            
        }
    }
    
    private func fetchFeed() {
        
        let id = self.id
        
        let session = Session.sharedSession
        
        session.sendRequest(GetRss<_RssFeed>(url: url, limit: 200)) { [weak self] result in
            switch result {
            case .Success(let response):
                let realm = try! Realm()
                try! realm.write {
                    let genre = realm.objectForPrimaryKey(_Genre.self, key: id)
                    response._genreId = genre?.id ?? 0
                    response._genre = genre
                    realm.add(response, update: true)
                }
                self?.trackIds = response.items.map { $0.id }
                self?.request(refreshing: false)
            case .Failure(let error):
                print(error)
            }
        }
    }
}