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

    private var search: Model.Search? = Model.Search(term: "") {
        didSet {
            guard let search = search else { return }
            updateTableModule()
            searchDisposeBag = DisposeBag()
            search.changes
                .subscribe(tableView.rx_itemUpdates())
                .addDisposableTo(searchDisposeBag)
            search.refresh()
        }
    }
    private var searchDisposeBag = DisposeBag()

    private let tableView = UITableView()
    private let searhBar = UISearchBar()


    init() {
        super.init(nibName: nil, bundle: nil)

        updateTableModule()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.closeAction))

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .interactive
//        tableView.tableHeaderView = searhBar
        searhBar.sizeToFit()

        navigationItem.titleView = searhBar


        tableView.rx_reachedBottom()
            .filter { $0 }
            .subscribeNext { [weak self] _ in
                self?.search?.fetch()
            }
            .addDisposableTo(disposeBag)

        searhBar.rx_text
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .doOnNext { str in
                print(str)
            }
            .subscribeNext { [weak self] str in
                self?.search = Model.Search(term: str)
            }
            .addDisposableTo(disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        searhBar.becomeFirstResponder()
    }

    private func updateTableModule() {

        modules[tableView] = TableViewModule(
            view: tableView,
            superview: { [unowned self] in self.view },
            controller: self,
            list: search!,
            onGenerate: { (self, tableView, element, indexPath) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
                if let track = self.search?[indexPath.row] {
                    cell.textLabel?.text = track.trackName
                }
                return cell
            },
            onSelect: { (self, tableView, element, indexPath) in
                tableView.deselectRow(at: indexPath, animated: true)

                guard let search = self.search else { return }

                let vc = AlbumDetailViewController(collection: search[indexPath.row].collection)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        )
    }

    @objc
    private func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}
