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

    private let genres = Genres()
    private let disposeBag = DisposeBag()
    
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        genres.changes
            .subscribeNext { [weak self] changes in
                guard let `self` = self else { return }
                switch changes {
                case .initial:
                    self.tableView.reloadData()
                case let .update(deletions, insertions, modifications):
                    self.tableView.beginUpdates()
                    
                    func indexPaths(indexes: [Int]) -> [NSIndexPath] {
                        return indexes.map { NSIndexPath(forRow: $0, inSection: 0) }
                    }
                    self.tableView.deleteRowsAtIndexPaths(indexPaths(deletions), withRowAnimation: .Automatic)
                    self.tableView.insertRowsAtIndexPaths(indexPaths(insertions), withRowAnimation: .Automatic)
                    self.tableView.reloadRowsAtIndexPaths(indexPaths(modifications), withRowAnimation: .Automatic)
                    
                    self.tableView.endUpdates()
                }
            }
            .addDisposableTo(disposeBag)
        
        genres.fetch()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
}

extension GenresViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let genre = genres[indexPath.row]
        cell.textLabel?.text = genre.name
        return cell
    }
}

extension GenresViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let genre = genres[indexPath.row]
        let vc = RssViewController(genre: genre)
    
        navigationController?.pushViewController(vc, animated: true)
    }
}
