//
//  ViewController.swift
//  Demo
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


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
        let settings = UIBarButtonItem(title: "設定", style: .plain, target: nil, action: nil)
        genres.navigationItem.rightBarButtonItem = settings
        settings.rx.tap.asDriver()
            .drive(UIBindingObserver(UIElement: genres) { vc, _ in
                let settings = SettingsViewController()
                vc.navigationController?.pushViewController(settings, animated: true)
            })
            .addDisposableTo(disposeBag)

        addChildViewController(nav)
        containerView.addSubview(nav.view)
        nav.view.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        nav.didMove(toParentViewController: self)

        var animator: UIViewPropertyAnimator?
        let pan = UIPanGestureRecognizer()
        pan.rx.event.asDriver()
            .drive(UIBindingObserver(UIElement: self) { vc, pan in
                switch pan.state {
                case .began:
                    let center = vc.containerView.center
                    let timing = UISpringTimingParameters(dampingRatio: 0.6)
                    animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: timing)
                    animator?.addAnimations {
                        vc.containerView.center = center
                    }
                case .changed:
                    let location = pan.translation(in: vc.view)
                    var moved = vc.containerView.center
                    moved.y += location.y
                    vc.containerView.center = moved
                    pan.setTranslation(.zero, in: vc.view)
                case .ended:
                    animator?.startAnimation()
                default:()
                }
            })
            .addDisposableTo(disposeBag)
        containerView.addGestureRecognizer(pan)
    }
}
