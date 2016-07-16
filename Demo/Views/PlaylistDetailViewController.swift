//
//  PlaylistDetailViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/17.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic
import RxSwift
import SnapKit


final class PlaylistDetailViewController: UIViewController {
    
    private let playlist: Model.MyPlaylist
    
    private let tableView = UITableView()
    
    private let disposeBag = DisposeBag()
    
    init(playlist: MyPlaylist) {
        self.playlist = Model.MyPlaylist(playlist: playlist)
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
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
        
        playlist.changes
            .subscribe(tableView.rx_itemUpdates())
            .addDisposableTo(disposeBag)
    }
}

extension PlaylistDetailViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let track = playlist[indexPath.row]
        cell.textLabel?.text = track.trackName
        return cell
    }
}

extension PlaylistDetailViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        player.add(track: playlist[indexPath.row])
    }
}
