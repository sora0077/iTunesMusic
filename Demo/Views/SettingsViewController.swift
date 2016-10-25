//
//  SettingsViewController.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/10/24.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import iTunesMusic


private extension Reactive where Base: Model.DiskCache {
    var diskSizeText: Observable<String> {
        return diskSizeInBytes.map { bytes in
            switch bytes {
            case 0...1024*1024:
                return String(format: "%.2fKB", Float(bytes)/1024)
            case 1024*1024...1024*1024*1024:
                return String(format: "%.2fMB", Float(bytes)/1024/1024)
            default:
                return String(format: "%.2fGB", Float(bytes)/1024/1024/1024)
            }
        }
    }
}


private protocol RowType {

    var cellClass: UITableViewCell.Type { get }

    func configure(cell: UITableViewCell, parent: UIViewController)

    func action(_ tableView: UITableView, at indexPath: IndexPath, parent: UIViewController)
}

extension RowType {

    func register(_ tableView: UITableView) {
        tableView.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
    }

    func cell(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: cellClass), for: indexPath)
        return cell
    }

    func action(_ tableView: UITableView, at indexPath: IndexPath, parent: UIViewController) {}
}

extension SettingsViewController {
    fileprivate enum Section: Int {
        case cache
    }
}

extension SettingsViewController.Section {
    var rows: [RowType] {
        switch self {
        case .cache:
            enum Row: Int, RowType {
                case cache

                var cellClass: UITableViewCell.Type {
                    switch self {
                    case .cache:
                        class Cell: UITableViewCell {
                            override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
                                super.init(style: .value1, reuseIdentifier: reuseIdentifier)
                            }

                            required init?(coder aDecoder: NSCoder) {
                                fatalError("init(coder:) has not been implemented")
                            }

                            override func prepareForReuse() {
                                super.prepareForReuse()
                                disposeBag = DisposeBag()
                            }
                        }
                        return Cell.self
                    }
                }

                func configure(cell: UITableViewCell, parent: UIViewController) {
                    cell.textLabel?.text = "キャッシュの削除"
                    if let text = cell.detailTextLabel?.rx.text {
                        Model.DiskCache.shared.rx.diskSizeText
                            .asDriver(onErrorJustReturn: "")
                            .drive(text)
                            .addDisposableTo(cell.disposeBag)
                    }
                }

                func action(_ tableView: UITableView, at indexPath: IndexPath, parent: UIViewController) {
                    let sheet = UIAlertController(title: "キャッシュの削除", message: "本当に削除しますか？", preferredStyle: .actionSheet)
                    sheet.addAction(UIAlertAction(title: "削除", style: .destructive) { action in
                        Model.DiskCache.shared.removeAll()
                            .subscribe(UIBindingObserver(UIElement: parent) { vc, _ in

                            })
                            .addDisposableTo(parent.disposeBag)
                    })
                    sheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { action in

                    })
                    parent.present(sheet, animated: true) {
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
            }
            return [Row.cache]
        }
    }
}

final class SettingsViewController: UIViewController {

    fileprivate let tableView = UITableView(frame: .zero, style: .grouped)

    fileprivate let sections: [Section] = [.cache]

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        sections.forEach {
            $0.rows.forEach {
                $0.register(tableView)
            }
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
    }
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = row.cell(tableView, at: indexPath)
        row.configure(cell: cell, parent: self)

        return cell
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        row.action(tableView, at: indexPath, parent: self)
    }
}
