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
    
    let artistButton = UIButton(type: .system)
    
    weak var parentController: UIViewController?
    
    init(parentController: UIViewController) {
        self.parentController = parentController
        super.init(frame: CGRect.zero)
        
        artworkImageView.clipsToBounds = true
        artworkImageView.contentMode = .scaleAspectFill
        
        addSubview(subheaderView)
        addSubview(artworkImageView)
        addSubview(artistButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        artworkImageView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(64)
            make.left.right.equalTo(self)
            make.bottom.equalTo(self).offset(0).priority(750)
//            if let parentController = parentController {
//                
//            }
            make.top.equalTo(parentController!.view.snp.top)
        }
        subheaderView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(64)
            make.height.equalTo(0)
            make.left.right.equalTo(self)
        }
        
        artistButton.snp.makeConstraints { make in
            make.bottom.right.equalTo(self).offset(-8)
        }
    }
}

private class TableViewCell: UITableViewCell {
    
    let button = UIButton(type: .system)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.rightMargin.equalTo(contentView).offset(-8)
            make.centerY.equalTo(contentView)
        }
        button.tintColor = UIColor.black()
        button.setTitle("Add", for: UIControlState())
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
    
    init(collection: iTunesMusic.Collection) {
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
            originalNavigationBarSettings.backgroundImage = bar.backgroundImage(for: .default)
            originalNavigationBarSettings.shadowImage = bar.shadowImage
        }
        
        view.addSubview(tableView)
        tableView.tableHeaderView = headerView
        automaticallyAdjustsScrollViewInsets = false
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.contentInset.bottom = tabBarController?.tabBar.frame.height ?? 0
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        
        headerView.setup()
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.superview!)
            make.width.equalTo(tableView.snp.width)
            make.height.equalTo(264)
        }
        let size = { Int($0 * UIScreen.main().scale) }
        let thumbnailURL = album.collection.artworkURL(size: size(view.frame.width/2))
        let artworkURL = album.collection.artworkURL(size: size(view.frame.width))
        headerView.artworkImageView.sd_setImage(with: thumbnailURL, placeholderImage: nil, options: [], progress: nil) { [weak wview=headerView] (image, error, type, url) in
            guard let view = wview else { return }
            DispatchQueue.main.async {
                view.artworkImageView.sd_setImage(with: artworkURL, placeholderImage: image)
            }
        }
        
        title = album.collection.name
        headerView.artistButton.setTitle(album.collection.artist.name, for: .normal)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(self.playAll))
        
        observe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let bar = navigationController?.navigationBar {
            
            bar.setBackgroundImage(UIImage(), for: .default)
            bar.shadowImage = UIImage()
            bar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white()]
            bar.setTitleVerticalPositionAdjustment(60, for: .default)
            bar.clipsToBounds = true
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let bar = navigationController?.navigationBar {
            bar.setBackgroundImage(originalNavigationBarSettings.backgroundImage, for: .default)
            bar.shadowImage = originalNavigationBarSettings.shadowImage
            bar.clipsToBounds = false
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .lightContent
    }
    
    @objc
    private func playAll() {
        print(Thread.isMainThread)
        player.add(playlist: album)
    }
    
    private func observe() {
        
        headerView.artistButton.rx_tap
            .subscribeNext { [weak self] _ in
                guard let `self` = self else { return }
                let vc = ArtistDetailViewController(artist: self.album.collection.artist)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            .addDisposableTo(disposeBag)
        
        tableView.rx_reachedBottom()
            .filter { $0 }
            .debounce(0.5, scheduler: MainScheduler.instance)
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
            .subscribe(rx_prefetchArtworkURLs(size: Int(60 * UIScreen.main().scale)))
            .addDisposableTo(disposeBag)
        
        album.refresh()
    }
}

extension AlbumDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
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
            navigationController?.navigationBar.setTitleVerticalPositionAdjustment(244 - offset, for: .default)
            if 244 < offset {
                
                navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0, for: .default)
            }
        } else {
            navigationController?.navigationBar.setTitleVerticalPositionAdjustment(60, for: .default)
            
        }
    }
}

private extension AlbumDetailViewController {
    
    @objc
    func addPlaylist(_ sender: UIButton, event: UIEvent) {
        guard
            let point = event.allTouches()?.first?.location(in: tableView),
            let indexPath = tableView.indexPathForRow(at: point)
        else { return }
        
        let track = album[indexPath.row]
        
        let playlist = Model.MyPlaylist(playlist: Model.MyPlaylists()[0])
        playlist.add(track: track)
    }
}

extension AlbumDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return album.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
        let track = album[indexPath.row]
        
        cell.detailTextLabel?.text = "\((indexPath as NSIndexPath).row + 1)"
        cell.textLabel?.text = track.trackName
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightUltraLight)
        if track.canPreview {
            cell.textLabel?.textColor = UIColor.black()
            cell.selectionStyle = .default
        } else {
            cell.textLabel?.textColor = UIColor.lightGray()
            cell.selectionStyle = .none
        }
        cell.button.removeTarget(nil, action: nil, for: [])
        cell.button.addTarget(self, action: #selector(self.addPlaylist(_:event:)), for: .touchUpInside)
        
        return cell
    }
}

extension AlbumDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
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

