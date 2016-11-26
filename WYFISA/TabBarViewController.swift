//
//  TabBarViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/11/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

func defaultCallback(page: Int){}

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {

    var captureButtonPtr: UIButton? = nil
    var onTabChange: (Int) -> () = defaultCallback
    var onPageChange: (Int) -> () = defaultCallback

    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 1
        self.delegate = self
        
        // Do any additional setup after loading the view.
        let scrollVC = self.selectedViewController as! ScrollViewController
        scrollVC.onPageChange = self.onPageChange
    }
    

    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        self.onTabChange(self.selectedIndex)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
