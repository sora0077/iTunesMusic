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

    typealias CellForRowAtIndexPath = (_ self: Controller, _ tableView: UITableView, _ element: List.Iterator.Element, _ indexPath: IndexPath) -> UITableViewCell

    typealias DidSelectRowAtIndexPath = (_ self: Controller, _ tableView: UITableView, _ element: List.Iterator.Element, _ indexPath: IndexPath) -> Void

    fileprivate let tableView: UITableView

    fileprivate let superview: () -> UIView

    fileprivate let list: List

    fileprivate weak var viewController: Controller?

    fileprivate let generator: CellForRowAtIndexPath

    fileprivate let selector: DidSelectRowAtIndexPath?

    init(view: UITableView,
         superview: @escaping () -> UIView,
         controller: Controller,
         list: List,
         onGenerate: CellForRowAtIndexPath,
         onSelect: DidSelectRowAtIndexPath? = nil) {
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
        return generator(viewController!, tableView, list[indexPath.row], indexPath)
    }

    //MARK: - UITableViewDelegate
    @objc
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let vc = viewController else { return }
        selector?(vc, tableView, list[indexPath.row], indexPath)
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
