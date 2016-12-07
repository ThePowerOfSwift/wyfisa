//
//  TabBarViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/11/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit


class TabBarViewController: UITabBarController, UITabBarControllerDelegate {

    var delegatingVC: InitViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 1
        self.delegate = self
        
        // Do any additional setup after loading the view.
        if let historyVC = self.selectedViewController as? HistoryViewController {
            self.delegatingVC.delegate = historyVC
        }
        
    }
    

    
    func applyDelegate(fromVC: InitViewController){
        self.delegatingVC = fromVC
    }

    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
