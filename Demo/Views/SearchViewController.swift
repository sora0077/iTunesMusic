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
import RxCocoa


enum SearchError: AppError {

    case none, error(Swift.Error)

    init(error: Swift.Error?) {
        self = error.map { .error($0) } ?? .none
    }

    var title: String {
        return "検索失敗"
    }
}


class SearchViewController: UIViewController {

    fileprivate var search: Model.Search = Model.Search(term: "") {
        didSet {
            searchDisposeBag = DisposeBag()
            search.trends.changes
                .subscribe(tableView.rx.itemUpdates())
                .addDisposableTo(searchDisposeBag)
            search.changes
                .subscribe(tableView.rx.itemUpdates { idx in (idx, 1) })
                .addDisposableTo(searchDisposeBag)
            action(search.refresh, error: SearchError.self)
        }
    }
    fileprivate var searchDisposeBag = DisposeBag()

    fileprivate let tableView = UITableView()
    fileprivate let searhBar = UISearchBar()

    init(query: String? = nil) {
        search = Model.Search(term: query ?? "")
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
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
        searhBar.text = search.name

        navigationItem.titleView = searhBar


        tableView.rx.reachedBottom()
            .filter { $0 }
            .subscribe(UIBindingObserver(UIElement: self) { vc, _ in
                action(vc.search.fetch, error: SearchError.self)
            })
            .addDisposableTo(disposeBag)

        searhBar.rx.text
            .debounce(0.3, scheduler: MainScheduler.instance)
            .filter { $0 != nil }
            .map { $0 ?? "" }
            .distinctUntilChanged()
            .do(onNext: { str in
                print(str)
            })
            .subscribe(UIBindingObserver(UIElement: self) { vc, str in
                vc.search = Model.Search(term: str)
            })
            .addDisposableTo(disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    @objc
    fileprivate func closeAction() {
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
