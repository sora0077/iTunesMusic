//
//  SearchViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic
import RxSwift


class SearchViewController: BaseViewController {

    private var search: Model.Search = Model.Search(term: "") {
        didSet {
            searchDisposeBag = DisposeBag()
            search.trends.changes
                .subscribe(tableView.rx_itemUpdates())
                .addDisposableTo(searchDisposeBag)
            search.changes
                .subscribe(tableView.rx_itemUpdates { idx in (idx, 1) })
                .addDisposableTo(searchDisposeBag)
            search.refresh()

            search.trends.refresh()
        }
    }
    private var searchDisposeBag = DisposeBag()

    private let tableView = UITableView()
    private let searhBar = UISearchBar()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closeAction))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .interactive
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.tableHeaderView = searhBar
        searhBar.sizeToFit()

        navigationItem.titleView = searhBar


        tableView.rx_reachedBottom()
            .filter { $0 }
            .subscribeNext { [weak self] _ in
                self?.search.fetch()
            }
            .addDisposableTo(disposeBag)

        searhBar.rx_text
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .do(onNext: { str in
                print(str)
            })
            .subscribeNext { [weak self] str in
                self?.search = Model.Search(term: str)
            }
            .addDisposableTo(disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        searhBar.becomeFirstResponder()
    }

    @objc
    private func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}

extension SearchViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return search.trends.count
        case 1:
            return search.count
        default:
            fatalError()
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = nil
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "\(search.trends.name) - \(search.trends[indexPath.row])"
        case 1:
            cell.textLabel?.text = search.track(at: indexPath.row).name
        default:
            fatalError()
        }
        return cell
    }
}

extension SearchViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
        case 0:
            self.search = Model.Search(term: search.trends[indexPath.row])
        default:
            let vc = AlbumDetailViewController(collection: search.track(at: indexPath.row).collection)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
