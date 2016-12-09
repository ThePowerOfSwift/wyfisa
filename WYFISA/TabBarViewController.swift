//
//  TabBarViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/11/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit


class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    let sharedOutlet = SharedOutlets.instance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 1
        self.delegate = self
        
        // Do any additional setup after loading the view.
        sharedOutlet.tabBarFrame = self.tabBar.frame
        sharedOutlet.notifyTabEnabled = {
            self.selectedIndex = 1
        }
        
    }
    
    override func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if self.selectedIndex == 1 {
            sharedOutlet.notifyTabDisabled()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
