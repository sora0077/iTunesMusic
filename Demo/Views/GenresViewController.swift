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


class BaseViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    var modules: [UIView: ViewModuleProtocol] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        modules.forEach { $0.1.install() }
    }
}

class GenresViewController: BaseViewController {

    private let genres = Model.Genres()
    
    private let tableView = UITableView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        modules[tableView] = TableViewModule(
            view: tableView,
            superview: { [unowned self] in self.view },
            controller: self,
            list: genres,
            onGenerate: { (self, tableView, element, indexPath) in
                let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
                let genre = self.genres[indexPath.row]
                cell.textLabel?.text = genre.name
                return cell
            },
            onSelect: { (self, tableView, element, indexPath) in
                let genre = self.genres[indexPath.row]
                let vc = RssViewController(genre: genre)
                
                self.navigationController?.pushViewController(vc, animated: true)
            }
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        genres.changes
            .subscribe(tableView.rx_itemUpdates())
            .addDisposableTo(disposeBag)
        
        genres.refresh()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
}
