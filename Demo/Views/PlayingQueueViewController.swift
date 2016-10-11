//
//  PlayingQueueViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/12.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import iTunesMusic


final class PlayingQueueViewController: UIViewController {

    fileprivate let tableView = UITableView()

    fileprivate var items: [Model.Track] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .clear
        tableView.rowHeight = 20
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
        tableView.snp.makeConstraints { make in
            make.top.equalTo(UIApplication.shared.statusBarFrame.height)
            make.leftMargin.equalTo(-10)
            make.right.bottom.equalTo(0)
        }

        func layoutItems() -> AnyObserver<[Model.Track]> {
            return UIBindingObserver(UIElement: self) { vc, tracks in
                vc.items = tracks
            }.asObserver()
        }

        player.playlingQueue
            .asDriver(onErrorJustReturn: [])
            .drive(layoutItems())
            .addDisposableTo(disposeBag)
    }

}

extension PlayingQueueViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let track = items[indexPath.row]
        cell.textLabel?.text = track.track?.name
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        if let font = cell.textLabel?.font {
            cell.textLabel?.font = font.withSize(9)
        }
        return cell
    }
}
