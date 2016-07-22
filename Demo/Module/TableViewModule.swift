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
    func install()
}


class TableViewModule<List: Swift.Collection, Controller: UIViewController where List.Index == Int, List.IndexDistance == Int>: NSObject, ViewModuleProtocol, UITableViewDataSource, UITableViewDelegate {
    
    typealias CellForRowAtIndexPath = (self: Controller, tableView: UITableView, element: List.Iterator.Element, indexPath: IndexPath) -> UITableViewCell
    
    typealias DidSelectRowAtIndexPath = (self: Controller, tableView: UITableView, element: List.Iterator.Element, indexPath: IndexPath) -> Void
    
    private let tableView: UITableView
    
    private let superview: () -> UIView
    
    private let list: List
    
    private weak var viewController: Controller?
    
    private let generator: CellForRowAtIndexPath
    
    private let selector: DidSelectRowAtIndexPath?
    
    init(view: UITableView,
         superview: () -> UIView,
         controller: Controller,
         list: List,
         onGenerate: CellForRowAtIndexPath,
         onSelect: DidSelectRowAtIndexPath? = nil)
    {
        self.superview = superview
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    @objc
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return generator(self: viewController!, tableView: tableView, element: list[(indexPath as NSIndexPath).row], indexPath: indexPath)
    }
    
    //MARK: - UITableViewDelegate
    @objc
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = viewController else { return }
        selector?(self: vc, tableView: tableView, element: list[(indexPath as NSIndexPath).row], indexPath: indexPath)
    }
}

extension TableViewModule {
    
    func install() {
        let superview = self.superview()
        superview.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(superview)
        }
    }
}
