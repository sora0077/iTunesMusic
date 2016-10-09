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

    private let containerView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }

        view.layer.cornerRadius = containerView.layer.cornerRadius
        view.layer.masksToBounds = false
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset.height = 2
        view.addTiltEffects(tilt: .front(depth: 10))


        let genres = GenresViewController()
        let nav = UINavigationController(rootViewController: genres)

        addChildViewController(nav)
        containerView.addSubview(nav.view)
        nav.view.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        nav.didMove(toParentViewController: self)
    }
}
