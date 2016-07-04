//
//  AlbumDetailViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/02.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit
import SDWebImage
import iTunesMusic


private class TableViewCell: UITableViewCell {
    
    let artworkImageView = UIImageView()
    
    let titleLabel = UILabel()
    
    let cacheMarkLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(artworkImageView)
        artworkImageView.snp_makeConstraints { make in
            make.top.left.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).priority(UILayoutPriorityDefaultHigh)
            make.width.equalTo(120)
            make.height.equalTo(120)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.snp_makeConstraints { make in
            make.left.equalTo(artworkImageView.snp_right).offset(8)
            make.right.equalToSuperview().offset(-40)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(cacheMarkLabel)
        cacheMarkLabel.text = "☑"
        cacheMarkLabel.snp_makeConstraints { make in
            make.right.equalToSuperview().offset(-4)
            make.bottom.equalToSuperview().offset(-4)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



class AlbumDetailViewController: UIViewController {
    
    enum CellType {
        case A
    }
    
    private let tableView = UITableView()
    
    private let album: Album
    private let disposeBag = DisposeBag()
    
    init(collection: Collection) {
        album = Album(collection: collection)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        tableView.delegate = nil
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
                self?.album.fetch()
            }
            .addDisposableTo(disposeBag)
        
        album.changes
            .subscribe(tableView.rx_itemUpdates())
            .addDisposableTo(disposeBag)
        
        album.changes
            .map { [weak self] _ in self?.album }
            .filter { $0 != nil }
            .map { $0! }
            .subscribe(rx_prefetchArtworkURLs(size: Int(60 * UIScreen.mainScreen().scale)))
            .addDisposableTo(disposeBag)
        
        album.fetch()
    }

}

extension AlbumDetailViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return album.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TableViewCell
        let track = album[indexPath.row]
        
        cell.detailTextLabel?.text = "\(indexPath.row + 1)"
        cell.titleLabel.text = track.trackName
        cell.cacheMarkLabel.hidden = !track.cached
        let size = { Int($0 * UIScreen.mainScreen().scale) }
        
        let artworkURL = track.artworkURL(size: size(120))
        cell.artworkImageView.sd_setImageWithURL(track.artworkURL(size: size(60)), placeholderImage: nil) { [weak wcell=cell] (image, error, type, url) in
            guard let cell = wcell else { return }
            dispatch_async(dispatch_get_main_queue()) {
                cell.artworkImageView.sd_setImageWithURL(artworkURL, placeholderImage: image)
            }
        }
        return cell
    }
}

extension AlbumDetailViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        print(album[indexPath.row])
        
        player.add(track: album[indexPath.row])
    }
}

