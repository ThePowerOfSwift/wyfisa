//
//  WYFISATabBarController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/14/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class WYFISATabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewWillAppear(animated: Bool) {
        self.selectedIndex = 1
    }
    override func viewDidAppear(animated: Bool) {
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}