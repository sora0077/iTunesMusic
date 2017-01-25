//
//  HistoryViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/18.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import iTunesMusic

private class TableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HistoryViewController: UIViewController {

    fileprivate let tableView = UITableView()

    fileprivate let history = Model.History.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.register(TableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }

        history.changes
            .subscribe(tableView.rx.itemUpdates())
            .addDisposableTo(disposeBag)
    }
}

extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let (track, played) = history[indexPath.row]
        cell.textLabel?.text = track.name
        cell.detailTextLabel?.text = "\(played)"
        return cell
    }
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let (track, _) = history[indexPath.row]
        guard track.canPreview else { return }

        UIApplication.shared.open(appURL(path: "/track/\(track.id)"))
    }
}
