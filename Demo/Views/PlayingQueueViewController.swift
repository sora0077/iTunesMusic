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


private extension Array {
    subscript (safe index: Int) -> Element? {
        if indices.contains(index) {
            return self[index]
        }
        return nil
    }
}


private final class TableView: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


final class PlayingQueueViewController: UIViewController {

    fileprivate enum Item {
        case track(PlayerTrackItem)
        case playlist(PlayerListItem)
    }

    fileprivate let tableView = UITableView()

    fileprivate var sections: [Item] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TableView.self, forCellReuseIdentifier: "Cell")
        tableView.backgroundColor = .clear
        tableView.rowHeight = 30
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
        tableView.snp.makeConstraints { make in
            make.top.equalTo(UIApplication.shared.statusBarFrame.height)
            make.leftMargin.equalTo(-10)
            make.right.bottom.equalTo(0)
        }

        player.playingQueue
            .asDriver(onErrorJustReturn: [])
            .drive(UIBindingObserver(UIElement: self) { vc, tracks in
                vc.sections = tracks.map {
                    switch $0 {
                    case let v as PlayerTrackItem:
                        return .track(v)
                    case let v as PlayerListItem:
                        return .playlist(v)
                    default: fatalError()
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    self.tableView.reloadData()
                }
            }.asObserver())
            .addDisposableTo(disposeBag)
    }

}

extension PlayingQueueViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .track:
            return 1
        case .playlist(let list):
            return list.tracks.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = sections[indexPath.section]

        func requestState(_ state: PlayerItem.ItemState?) -> String {
            guard let state = state else {
                return "requesting"
            }
            switch state {
            case .waiting:
                return "waiting"
            case .readyToPlay:
                return "readyToPlay"
            case .nowPlaying:
                return "nowPlaying"
            case .didFinishPlaying:
                return "didFinishPlaying"
            }
        }

        switch item {
        case .track(let track):
            cell.textLabel?.text = track.name
            cell.detailTextLabel?.text = requestState(track.items.first)
        case .playlist(let list):
            let track = list.tracks[indexPath.row]
            cell.textLabel?.text = track.name
            cell.detailTextLabel?.text = requestState(list.items[safe: indexPath.row])
        }
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        cell.indentationLevel = indexPath.row == 0 ? 0 : 1
        cell.backgroundColor = .clear
        if let font = cell.textLabel?.font {
            cell.textLabel?.font = font.withSize(8)
        }
        if let font = cell.detailTextLabel?.font {
            cell.detailTextLabel?.font = font.withSize(7)
        }
        return cell
    }
}

extension PlayingQueueViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        player.removeAll()
    }
}
