//
//  ArtistDetailViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic
import RxSwift
import SnapKit

fileprivate class TableViewCell: UITableViewCell {

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

final class ArtistDetailViewController: UIViewController {

    fileprivate let artist: Model.Artist

    fileprivate let tableView = UITableView()

    init(artist: Artist) {
        self.artist = Model.Artist(artist: artist)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white

        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")

        artist.changes
            .bind(to: tableView.rx.itemUpdates())
            .addDisposableTo(disposeBag)

        action(artist.refresh)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension ArtistDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artist.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TableViewCell

        let collection = artist[indexPath.row]
        cell.titleLabel.text = collection.name
        cell.artworkImageView.setArtwork(of: collection, size: 120)
        return cell
    }
}

extension ArtistDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let vc = AlbumDetailViewController(collection: artist[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}
