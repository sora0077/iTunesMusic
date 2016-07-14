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


class SearchViewController: UIViewController {
    
    private var search: Model.Search? {
        didSet {
            
            guard let search = search else { return }
            searchDisposeBag = DisposeBag()
            search.changes
                .subscribe(tableView.rx_itemUpdates())
                .addDisposableTo(searchDisposeBag)
            search.fetch()
        }
    }
    private let disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()
    
    private let tableView = UITableView()
    private let searhBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(self.closeAction))
        
        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.keyboardDismissMode = .Interactive
//        tableView.tableHeaderView = searhBar
        searhBar.sizeToFit()
        searhBar.delegate = self

        navigationItem.titleView = searhBar
        
        
        tableView.rx_reachedBottom()
            .filter { $0 }
            .subscribeNext { [weak self] _ in
                self?.search?.fetch()
            }
            .addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        searhBar.becomeFirstResponder()
    }
    
    @objc
    private func closeAction() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return search?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        if let search = search {
            let track = search[indexPath.row]
            cell.textLabel?.text = track.trackName
        }
        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let search = search else { return }
        
        let vc = AlbumDetailViewController(collection: search[indexPath.row].collection)
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        if let text = searchBar.text where !text.isEmpty {
            search = Model.Search(term: text)
        }
    }
}
