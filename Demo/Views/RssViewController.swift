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
import SDWebImage
import SnapKit


private class TableViewCell: UITableViewCell {
    
    let artworkImageView = UIImageView()
    
    let titleLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(artworkImageView)
        artworkImageView.snp_makeConstraints { make in
            make.top.left.equalTo(self.contentView)
//            make.left.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).priority(UILayoutPriorityDefaultHigh)
            make.width.equalTo(120)
            make.height.equalTo(120)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(artworkImageView.snp_right).offset(8)
            make.right.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
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
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.rx_reachedBottom()
            .filter { $0 }
            .subscribeNext { [weak self] _ in
                self?.rss.fetch()
            }
            .addDisposableTo(disposeBag)
        
        rss.changes
            .subscribe(tableView.rx_itemUpdates())
            .addDisposableTo(disposeBag)
        
        rss.changes
            .map { [weak self] _ in self?.rss }
            .filter { $0 != nil }
            .map { $0! }
            .subscribe(rx_prefetchArtworkURLs(size: 60))
            .addDisposableTo(disposeBag)
        
        rss.fetch()
    }
}

extension RssViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rss.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TableViewCell
        let track = rss[indexPath.row]
        
//        print(track.artworkURL(Int(120 * UIScreen.mainScreen().scale)))
        
        cell.detailTextLabel?.text = "\(indexPath.row + 1)"
        cell.titleLabel.text = track.trackName
        
        cell.artworkImageView.sd_setImageWithURL(track.artworkURL(size: 120), placeholderImage: nil) { [weak wcell=cell] (image, error, type, url) in
            guard let cell = wcell else { return }
            cell.artworkImageView.sd_setImageWithURL(track.artworkURL(size: Int(120 * UIScreen.mainScreen().scale)), placeholderImage: image)
        }
        return cell
    }
}

extension RssViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        player.add(track: rss[indexPath.row])
    }
}
