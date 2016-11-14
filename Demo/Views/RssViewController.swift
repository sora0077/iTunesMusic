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
import RxCocoa
import SnapKit


class RssViewController: UIViewController {

    fileprivate private(set) var rss: Model.Rss

    fileprivate let tableView = UITableView()

    init(genre: Genre) {
        rss = Model.Rss(genre: genre)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(self, " deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        view.backgroundColor = tableView.backgroundColor
        tableView.dataSource = self
        tableView.delegate = self
        [
            "AlbumListTopTableViewCell",
            "AlbumListMiddleTableViewCell",
            "AlbumListBottomTableViewCell",
            "AlbumListTopBottomTableViewCell"
        ].forEach { cell in
            tableView.register(
                UINib(nibName: cell, bundle: nil),
                forCellReuseIdentifier: cell
            )
        }
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(self.playAll))

        let refreshControl = UIRefreshControl()
        refreshControl.rx.controlEvent(.valueChanged)
            .delay(0.8, scheduler: MainScheduler.instance)
            .subscribe(UIBindingObserver(UIElement: self) { vc, _ in
                action(partial(vc.rss.refresh, true))
            })
            .addDisposableTo(disposeBag)
        tableView.refreshControl = refreshControl

        startObserving()

        action(rss.refresh)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    private func startObserving() {

        tableView.rx.reachedBottom()
            .filter { $0 }
            .subscribe(UIBindingObserver(UIElement: self) { vc, _ in
                action(vc.rss.fetch)
            })
            .addDisposableTo(disposeBag)

        rss.changes
            .subscribe(tableView.rx.itemUpdates())
            .addDisposableTo(disposeBag)

        rss.changes
            .subscribe(UIBindingObserver(UIElement: self) { vc, _ in
                vc.tableView.refreshControl?.endRefreshing()
            })
            .addDisposableTo(disposeBag)

        rss.changes
            .map { [weak self] _ in self?.rss }
            .filter { $0 != nil }
            .map { $0! }
            .subscribe(prefetchArtworkURLs(size: Int(60 * UIScreen.main.scale)))
            .addDisposableTo(disposeBag)

        rss.requestState
            .subscribe(UIBindingObserver(UIElement: self) { vc, state in
                func title() -> String {
                    switch state {
                    case .none:
                        return ""
                    case .done:
                        return "done"
                    case .requesting:
                        return "通信中"
                    case .error:
                        return "エラー"
                    }
                }
                vc.title = title()
            })
            .addDisposableTo(disposeBag)

        if let refreshControl = tableView.refreshControl {
            rss.requestState
                .map { $0 != .requesting }
                .distinctUntilChanged()
                .asDriver(onErrorJustReturn: false)
                .drive(refreshControl.rx.isEnabled)
                .addDisposableTo(disposeBag)
        }
    }

    @objc
    fileprivate func playAll() {
        print(Thread.isMainThread)
        player.add(playlist: rss)
    }
}

extension RssViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rss.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = rss[indexPath.row]

        func dequeueCell() -> AlbumListCellType {

            func identifier() -> String {
                let index = indexPath.row
                let prevOpt: Track? = index == 0 ? nil : rss[index - 1]
                let nextOpt: Track? = index == rss.count - 1 ? nil : rss[index + 1]

                guard let prev = prevOpt else {
                    if track.collection.id == nextOpt?.collection.id {
                        return "AlbumListTopTableViewCell"
                    } else {
                        return "AlbumListTopBottomTableViewCell"
                    }
                }

                guard let next = nextOpt else {
                    if prev.collection.id == track.collection.id {
                        return "AlbumListBottomTableViewCell"
                    } else {
                        return "AlbumListTopBottomTableViewCell"
                    }
                }

                guard prev.collection.id == track.collection.id else {
                    if track.collection.id == next.collection.id {
                        return "AlbumListTopTableViewCell"
                    }
                    return "AlbumListTopBottomTableViewCell"
                }

                if track.collection.id == next.collection.id {
                    return "AlbumListMiddleTableViewCell"
                }
                return "AlbumListBottomTableViewCell"
            }

            return tableView.dequeueReusableCell(withIdentifier: identifier(), for: indexPath) as! AlbumListCellType
        }

        let cell = dequeueCell()
        cell.artworkImageView?.setArtwork(of: track, size: 100)
        cell.albumNameLabel?.text = track.collection.name
        cell.trackNameLabel.text = track.name

        return cell as! UITableViewCell
    }
}

extension RssViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = rss[indexPath.row]

        let vc = AlbumDetailViewController(collection: track.collection)
        navigationController?.pushViewController(vc, animated: true)
    }
}
