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
    
    weak var parentController: UIViewController?
    
    init(parentController: UIViewController) {
        self.parentController = parentController
        super.init(frame: CGRectZero)
        
        artworkImageView.clipsToBounds = true
        artworkImageView.contentMode = .ScaleAspectFill
        
        addSubview(subheaderView)
        addSubview(artworkImageView)
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
        
        view.addSubview(tableView)
        tableView.tableHeaderView = headerView
        
        if let bar = navigationController?.navigationBar {
            originalNavigationBarSettings.backgroundImage = bar.backgroundImageForBarMetrics(.Default)
            originalNavigationBarSettings.shadowImage = bar.shadowImage
        }
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        automaticallyAdjustsScrollViewInsets = false
        
        tableView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        
        headerView.setup()
        
        headerView.snp_makeConstraints { make in
//            make.top.equalTo(view.snp_top)
            make.top.equalToSuperview()
            make.width.equalTo(tableView.snp_width)
            make.height.equalTo(164)
//            make.height.equalTo(100).priority(750)
//            make.height.greaterThanOrEqualTo(navigationController?.navigationBar.frame.height ?? 0)
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

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(originalNavigationBarSettings.backgroundImage, forBarMetrics: .Default)
            bar.shadowImage = originalNavigationBarSettings.shadowImage
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    var showBlur: Bool = false
}

extension AlbumDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let offset = scrollView.contentOffset.y
        if offset > 100 && !showBlur {
            showBlur = true
        } else if offset < 100 && showBlur {
            showBlur = false
        }
        
        if 0 < offset && offset < 100 {
            let radius = Float(round(offset / 10))
            if headerView.artworkImageView.blurRadius != radius {
                print(radius)
                headerView.artworkImageView.blurRadius = radius
            }
        }
    }
}

extension AlbumDetailViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return album.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let track = album[indexPath.row]
        
        cell.detailTextLabel?.text = "\(indexPath.row + 1)"
        cell.textLabel?.text = track.trackName
        return cell
    }
}

extension AlbumDetailViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
      
//        print(album[indexPath.row])
//        artist = Model.Artist(artist: album[indexPath.row].artist)
//        artist.fetch()
//        artist.changes.subscribeNext { changes in
//            for album in self.artist {
//                print(album)
//            }
//        }.addDisposableTo(disposeBag)
        
        print(album[indexPath.row].collection)
        
        player.add(track: album[indexPath.row])
    }
}

