//
//  RssViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic
import RxSwift


private class TableViewCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class RssViewController: UIViewController {
    
    private let rss: Rss
    private let disposeBag = DisposeBag()
    
    private let tableView = UITableView()
    
    init(genre: Genre) {
        rss = Rss(genre: genre)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "Cell")
        
        tableView.rx_reachedBottom()
            .filter { $0 }
            .subscribeNext { [weak self] _ in
                self?.rss.fetch()
            }
            .addDisposableTo(disposeBag)
        
        rss.changes
            .subscribe(tableView.rx_itemUpdates())
            .addDisposableTo(disposeBag)
        
        rss.fetch()
    }
}

extension RssViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rss.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let track = rss[indexPath.row]
        
        cell.detailTextLabel?.text = "\(indexPath.row + 1)"
        cell.textLabel?.text = track.trackName
        return cell
    }
}

extension RssViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        player.add(track: rss[indexPath.row])
    }
}
