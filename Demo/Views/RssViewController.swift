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
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class RssViewController: BaseViewController {

    private let rss: Model.Rss

    private let tableView = UITableView()

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
                cell.titleLabel.text = track.trackName
                let size = { Int($0 * UIScreen.main().scale) }

                let artworkURL = track.artworkURL(size: size(120))
                cell.artworkImageView.sd_setImage(with: track.artworkURL(size: size(60)), placeholderImage: nil, options: [], progress: nil) { [weak wcell=cell] (image, error, type, url) in
                    guard let cell = wcell else { return }
                    DispatchQueue.main.async {
                        cell.artworkImageView.sd_setImage(with: artworkURL, placeholderImage: image)
                    }
                }
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
            .subscribe(rx_prefetchArtworkURLs(size: Int(60 * UIScreen.main().scale)))
            .addDisposableTo(disposeBag)

        rss.requestState
            .subscribeNext { [weak self] state in
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
            }
            .addDisposableTo(disposeBag)

        rss.refresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    @objc
    private func playAll() {
        print(Thread.isMainThread)
        player.add(playlist: rss)
    }
}
