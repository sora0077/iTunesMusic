//
//  GenresViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic
import RxSwift
import SnapKit


class GenresViewController: UIViewController {

    fileprivate let genres = Model.Genres()

    fileprivate let tableView = UITableView()


    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }

        genres.changes
            .subscribe(tableView.rx.itemUpdates())
            .addDisposableTo(disposeBag)

        genres.refresh(ifError: CommonError.self, level: AppErrorLevel.alert)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension GenresViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.selectionStyle = .blue
        cell.textLabel?.text = genres[indexPath.row].name
        cell.textLabel?.textColor = .white
        cell.textLabel?.backgroundColor = .clear
        cell.backgroundColor = UIColor(hex: 0x20201e, alpha: 0.95)
        return cell
    }
}

extension GenresViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let vc = RssViewController(genre: genres[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
}
