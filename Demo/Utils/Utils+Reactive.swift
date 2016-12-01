//
//  Utils+Reactive.swift
//  iTunesMusic
//
//  Created by 林達也 on 2016/08/21.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import Foundation
import iTunesMusic
import RxSwift
import RxCocoa


func prefetchArtworkURLs<P: Playlist>(size: Int) -> AnyObserver<P> where P: Swift.Collection, P.Iterator.Element == Track {
    return AnyObserver { on in
        if case .next(let playlist) = on {
            let urls = playlist.flatMap { $0.artworkURL(size: size) }
            DispatchQueue.global(qos: .background).async {
                prefetchImages(with: urls)
            }
        }
    }
}

protocol _Optional {
    associatedtype Element
    var unsafelyUnwrapped: Element { get }
}

extension Optional: _Optional {
    typealias Element = Wrapped
}

extension ObservableType where E: _Optional {
    func flatMap() -> Observable<E.Element> {
        func notNil(_ val: Any?) -> Bool { return val != nil }
        return filter(notNil).map({ $0.unsafelyUnwrapped })
    }
}

extension Reactive where Base: UIScrollView {

    func reachedBottom(offsetRatio: CGFloat = 0) -> Observable<Bool> {
        return contentOffset
            .map { [weak base=base] contentOffset in
                guard let scrollView = base else { return false }

                let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
                let y = contentOffset.y + scrollView.contentInset.top
                let threshold = max(0.0, scrollView.contentSize.height - visibleHeight - visibleHeight * offsetRatio)
                return y > threshold
            }
            .throttle(0.1, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
    }
}


extension UITableView {

    private struct UITableViewKey {
        static var isMoving: UInt8 = 0
    }

    var isMoving: Bool {
        set {
            objc_setAssociatedObject(self, &UITableViewKey.isMoving, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &UITableViewKey.isMoving) as? Bool ?? false
        }
    }

    func performUpdates(deletions: [IndexPath], insertions: [IndexPath], modifications: [IndexPath]) {
        beginUpdates()
        if isMoving && deletions.count == insertions.count && modifications.isEmpty {
            isMoving = false
            reloadSections(IndexSet(0..<numberOfSections), with: .automatic)
        } else {
            if !deletions.isEmpty {
                deleteRows(at: deletions, with: .automatic)
            }
            if !insertions.isEmpty {
                insertRows(at: insertions, with: .top)
            }
            if !modifications.isEmpty {
                reloadRows(at: modifications, with: .automatic)
            }
        }
        endUpdates()
    }
}

extension Reactive where Base: UITableView {

    func itemUpdates(_ configure: ((_ index: Int) -> (row: Int, section: Int))? = nil) -> AnyObserver<CollectionChange> {
        return UIBindingObserver(UIElement: base) { tableView, changes in
            switch changes {
            case .initial:
                tableView.reloadData()
            case let .update(deletions: deletions, insertions: insertions, modifications: modifications):
                func indexPath(_ i: Int) -> IndexPath {
                    let (row, section) = configure?(i) ?? (i, 0)
                    return IndexPath(row: row, section: section)
                }
                tableView.performUpdates(
                    deletions: deletions.map(indexPath),
                    insertions: insertions.map(indexPath),
                    modifications: modifications.map(indexPath)
                )
            }
            }.asObserver()
    }
}
