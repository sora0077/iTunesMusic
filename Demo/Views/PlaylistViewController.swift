//
//  PlaylistViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/16.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit
import iTunesMusic

final class PlaylistViewController: UIViewController {

    fileprivate let playlists = Model.MyPlaylists()

    fileprivate let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        playlists.changes
            .subscribe(tableView.rx.itemUpdates())
            .addDisposableTo(disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension PlaylistViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let playlist = playlists[indexPath.row]

        cell.textLabel?.text = playlist.title
        return cell
    }
}

extension PlaylistViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let vc = PlaylistDetailViewController(playlist: playlists[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}
