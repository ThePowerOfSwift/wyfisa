//
//  FirstNavigationViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/25/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

class FirstNavigationViewController: UINavigationController {

    var didOnboarding = false
    var firstLaunch = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.tan()
    }
    
    override func viewDidAppear(animated: Bool) {
        // detect first launch and do onboarding if we havent yet
        if firstLaunch == true {
            if self.didOnboarding == false {
                self.performSegueWithIdentifier("onboardsegue", sender: nil)
                self.didOnboarding = true
            }
        } else {
            self.performSegueWithIdentifier("topicsegue", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func unwindFromOnboarding(segue: UIStoryboardSegue) {
        // when unwinding from onboard go directly to topic segue
        self.performSegueWithIdentifier("topicsegue", sender: nil)
    }
    

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}
