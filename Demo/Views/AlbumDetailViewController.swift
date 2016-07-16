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


private final class HeaderView: UIView {
    
    let artworkImageView = EasyBlurImageView()
    
    let subheaderView = UIView()
    
    let artistButton = UIButton(type: .System)
    
    weak var parentController: UIViewController?
    
    init(parentController: UIViewController) {
        self.parentController = parentController
        super.init(frame: CGRectZero)
        
        artworkImageView.clipsToBounds = true
        artworkImageView.contentMode = .ScaleAspectFill
        
        addSubview(subheaderView)
        addSubview(artworkImageView)
        addSubview(artistButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        artworkImageView.snp_makeConstraints { make in
            make.height.greaterThanOrEqualTo(64)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(0).priority(750)
//            if let parentController = parentController {
//                
//            }
            make.top.equalTo(parentController!.view.snp_top)
        }
        subheaderView.snp_makeConstraints { make in
            make.top.equalToSuperview().offset(64)
            make.height.equalTo(0)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        artistButton.snp_makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.right.equalToSuperview().offset(-8)
        }
    }
}

private class TableViewCell: UITableViewCell {
    
    let button = UIButton(type: .System)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(button)
        button.snp_makeConstraints { make in
            make.rightMargin.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        button.tintColor = UIColor.blackColor()
        button.setTitle("Add", forState: .Normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UINavigationController {
    
    public override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return visibleViewController
    }
}


class AlbumDetailViewController: UIViewController {
    
    private lazy var headerView: HeaderView = HeaderView(parentController: self)
    
    private let tableView = UITableView()
    
    private let album: Model.Album
    private let disposeBag = DisposeBag()
    
    var artist: Model.Artist!
    
    init(collection: Collection) {
        album = Model.Album(collection: collection)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var originalNavigationBarSettings: (backgroundImage: UIImage?, shadowImage: UIImage?) = (nil, nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let bar = navigationController?.navigationBar {
            originalNavigationBarSettings.backgroundImage = bar.backgroundImageForBarMetrics(.Default)
            originalNavigationBarSettings.shadowImage = bar.shadowImage
        }
        
        view.addSubview(tableView)
        tableView.tableHeaderView = headerView
        automaticallyAdjustsScrollViewInsets = false
        
        tableView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        
        headerView.setup()
        
        headerView.snp_makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalTo(tableView.snp_width)
            make.height.equalTo(264)
        }
        let size = { Int($0 * UIScreen.mainScreen().scale) }
        let thumbnailURL = album.collection.artworkURL(size: size(view.frame.width/2))
        let artworkURL = album.collection.artworkURL(size: size(view.frame.width))
        headerView.artworkImageView.sd_setImageWithURL(thumbnailURL, placeholderImage: nil) { [weak wview=headerView] (image, error, type, url) in
            guard let view = wview else { return }
            dispatch_async(dispatch_get_main_queue()) {
                view.artworkImageView.sd_setImageWithURL(artworkURL, placeholderImage: image)
            }
        }
        
        title = album.collection.name
        headerView.artistButton.setTitle(album.collection.artist.name, forState: .Normal)
        headerView.artistButton.rx_tap
            .subscribeNext { [weak self] _ in
                guard let `self` = self else { return }
                let vc = ArtistDetailViewController(artist: self.album.collection.artist)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .addDisposableTo(disposeBag)
        
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
        
        album.refresh()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let bar = navigationController?.navigationBar {
            
            bar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
            bar.shadowImage = UIImage()
            bar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
            bar.setTitleVerticalPositionAdjustment(60, forBarMetrics: .Default)
            bar.clipsToBounds = true
        }
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(originalNavigationBarSettings.backgroundImage, forBarMetrics: .Default)
            bar.shadowImage = originalNavigationBarSettings.shadowImage
            bar.clipsToBounds = false
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

extension AlbumDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        
        if offset < 0 {
            if headerView.artworkImageView.blurRadius != 0 {
                headerView.artworkImageView.blurRadius = 0
            }
        }
        if 0 < offset && offset < 200 {
            let radius = Float(round(offset / 10))
            if headerView.artworkImageView.blurRadius != radius {
                print(radius)
                headerView.artworkImageView.blurRadius = radius
            }
        }
        if 200 < offset {
            if headerView.artworkImageView.blurRadius != 20 {
                headerView.artworkImageView.blurRadius = 20
            }
            navigationController?.navigationBar.setTitleVerticalPositionAdjustment(244 - offset, forBarMetrics: .Default)
            if 244 < offset {
                
                navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0, forBarMetrics: .Default)
            }
        } else {
            navigationController?.navigationBar.setTitleVerticalPositionAdjustment(60, forBarMetrics: .Default)
            
        }
    }
}

private extension AlbumDetailViewController {
    
    @objc
    func addPlaylist(sender: UIButton, event: UIEvent) {
        guard
            let point = event.allTouches()?.first?.locationInView(tableView),
            indexPath = tableView.indexPathForRowAtPoint(point)
        else { return }
        
        let track = album[indexPath.row]
        
        let playlist = Model.MyPlaylist(playlist: Model.MyPlaylists()[0])
        playlist.add(track: track)
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
        cell.textLabel?.text = track.trackName
        if track.canPreview {
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.selectionStyle = .Default
        } else {
            cell.textLabel?.textColor = UIColor.lightGrayColor()
            cell.selectionStyle = .None
        }
        cell.button.removeTarget(nil, action: nil, forControlEvents: [])
        cell.button.addTarget(self, action: #selector(self.addPlaylist(_:event:)), forControlEvents: .TouchUpInside)
        
        return cell
    }
}

extension AlbumDetailViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let track = album[indexPath.row]
        guard track.canPreview else { return }
      
        print(track)
//        artist = Model.Artist(artist: album[indexPath.row].artist)
//        artist.fetch()
//        artist.changes.subscribeNext { changes in
//            for album in self.artist {
//                print(album)
//            }
//        }.addDisposableTo(disposeBag)
        
        player.add(track: track)
    }
}

