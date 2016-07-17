//
//  ViewController.swift
//  Demo
//
//  Created by 林達也 on 2016/06/26.
//  Copyright © 2016年 jp.sora0077. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let tab = UITabBarController()
        tab.viewControllers = [
            UINavigationController(rootViewController: GenresViewController()),
            UINavigationController(rootViewController: PlaylistViewController())
        ]
        
        presentViewController(tab, animated: true, completion: nil)
        
        tab.viewControllers![0].childViewControllers[0].navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Search,
            target: self,
            action: #selector(self.searchAction)
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc
    private func searchAction() {
        let vc = SearchViewController()
        let nav = UINavigationController(rootViewController: vc)
        
        presentedViewController?.presentViewController(nav, animated: true, completion: nil)
    }
}

