//
//  TableViewModule.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/07/20.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import iTunesMusic
import SnapKit


protocol ViewModuleProtocol {
    func install(superview: UIView)
}


class TableViewModule<List: CollectionType, Controller: UIViewController where List.Index.Distance == Int, List.Index == Int>: NSObject, ViewModuleProtocol, UITableViewDataSource, UITableViewDelegate {
    
    typealias CellForRowAtIndexPath = (`self`: Controller, tableView: UITableView, element: List.Generator.Element, indexPath: NSIndexPath) -> UITableViewCell
    
    typealias DidSelectRowAtIndexPath = (`self`: Controller, tableView: UITableView, element: List.Generator.Element, indexPath: NSIndexPath) -> Void
    
    private let tableView: UITableView
    
    private let list: List
    
    private weak var viewController: Controller?
    
    private let generator: CellForRowAtIndexPath
    
    private let selector: DidSelectRowAtIndexPath?
    
    init(list: List, view: UITableView, controller: Controller, onGenerate: CellForRowAtIndexPath, onSelect: DidSelectRowAtIndexPath? = nil) {
        self.list = list
        tableView = view
        viewController = controller
        generator = onGenerate
        selector = onSelect
        super.init()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    //MARK: - UITableViewDataSource
    @objc
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    @objc
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return generator(self: viewController!, tableView: tableView, element: list[indexPath.row], indexPath: indexPath)
    }
    
    //MARK: - UITableViewDelegate
    @objc
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let vc = viewController else { return }
        selector?(self: vc, tableView: tableView, element: list[indexPath.row], indexPath: indexPath)
    }
}

extension TableViewModule {
    
    func install(superview: UIView) {
        superview.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
