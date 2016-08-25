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
import SnapKit


fileprivate class TableViewCell: UITableViewCell {

    let artworkImageView = UIImageView()

    let titleLabel = UILabel()

    let albumLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(artworkImageView)
        artworkImageView.snp.makeConstraints { make in
            make.top.left.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView).priority(UILayoutPriorityDefaultHigh)
            make.width.equalTo(120)
            make.height.equalTo(120)
        }

        contentView.addSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(artworkImageView.snp.right).offset(8)
            make.right.equalTo(contentView).offset(-40)
            make.centerY.equalTo(contentView)
        }

        contentView.addSubview(albumLabel)
        albumLabel.numberOfLines = 0
        albumLabel.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        albumLabel.snp.makeConstraints { make in
            make.left.equalTo(artworkImageView.snp.right).offset(24)
            make.right.equalTo(contentView).offset(-40)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.lessThanOrEqualTo(contentView.snp.bottom).offset(-8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class RssViewController: BaseViewController {

    fileprivate let rss: Model.Rss

    fileprivate let tableView = UITableView()

    init(genre: Genre) {
        rss = Model.Rss(genre: genre)
        super.init(nibName: nil, bundle: nil)

        modules[tableView] = TableViewModule(
            view: tableView,
            superview: { [unowned self] in self.view },
            controller: self,
            list: rss,
            onGenerate: { (self, tableView, element, indexPath) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell
                let track = self.rss[indexPath.row]

                cell.detailTextLabel?.text = "\(indexPath.row + 1)"
                cell.titleLabel.text = track.name
                cell.artworkImageView.setArtwork(of: track, size: 120)
                cell.albumLabel.text = track.collection.name
                return cell
            },
            onSelect: { (self, tableView, element, indexPath) in
                let vc = AlbumDetailViewController(collection: self.rss[indexPath.row].collection)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(self, " deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(self.playAll))

        tableView.rx.reachedBottom()
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.rss.fetch(ifError: CommonError.self, level: AppErrorLevel.alert)
            })
            .addDisposableTo(disposeBag)

        rss.changes
            .subscribe(tableView.rx.itemUpdates())
            .addDisposableTo(disposeBag)

        rss.changes
            .map { [weak self] _ in self?.rss }
            .filter { $0 != nil }
            .map { $0! }
            .subscribe(prefetchArtworkURLs(size: Int(60 * UIScreen.main.scale)))
            .addDisposableTo(disposeBag)

        rss.requestState
            .subscribe(onNext: { [weak self] state in
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
                self?.title = title()
            })
            .addDisposableTo(disposeBag)

        rss.refresh(ifError: CommonError.self, level: AppErrorLevel.alert)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    @objc
    fileprivate func playAll() {
        print(Thread.isMainThread)
        player.add(playlist: rss)
    }
}
