//
//  ViewController.swift
//  Demo
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift


extension UIViewController {

    private struct Key {
        static var disposeBag: UInt8 = 0
    }

    var disposeBag: DisposeBag {
        if let bag = objc_getAssociatedObject(self, &Key.disposeBag) as? DisposeBag {
            return bag
        }
        let bag = DisposeBag()
        objc_setAssociatedObject(self, &Key.disposeBag, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return bag
    }
}



class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        let tab = UITabBarController()
//        tab.viewControllers = [
//            UINavigationController(rootViewController: GenresViewController()),
//            UINavigationController(rootViewController: PlaylistViewController())
//        ]
//
//        present(tab, animated: true, completion: nil)
//
//        tab.viewControllers![0].childViewControllers[0].navigationItem.rightBarButtonItem = UIBarButtonItem(
//            barButtonSystemItem: .search,
//            target: self,
//            action: #selector(self.searchAction)
//        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    fileprivate func searchAction() {
        let vc = SearchViewController()
        let nav = UINavigationController(rootViewController: vc)

        presentedViewController?.present(nav, animated: true, completion: nil)
    }
}

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let genres = GenresViewController()
        let nav = UINavigationController(rootViewController: genres)

        addChildViewController(nav)
        view.addSubview(nav.view)
        nav.didMove(toParentViewController: self)
    }
}
