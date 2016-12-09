//
//  InitViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/11/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

protocol CaptureButtonDelegate: class {
    func didPressCaptureButton(sender: InitViewController)
    func didReleaseCaptureButton(sender: InitViewController) -> Bool
}

class SharedOutlets {
    static let instance = SharedOutlets()
    weak var captureDelegate:CaptureButtonDelegate?
    var tabBarFrame: CGRect? = nil
    var notifyTabEnabled = notifyCallback
    var notifyTabDisabled = notifyCallback
}

class InitViewController: UIViewController {

    @IBOutlet var captureButton: UIButton!
    @IBOutlet var pageController: UIPageControl!
    
    var tabVC: TabBarViewController? = nil
    var composeTabActive: Bool = true
    let sharedOutlet = SharedOutlets.instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sharedOutlet.notifyTabDisabled = self.disableCaptureButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // entered capture tab
    @IBAction func didSPressCaptureButton(sender: AnyObject) {
        
        
        if (self.composeTabActive == false) {
            // just activate don't start scanning
            self.sharedOutlet.notifyTabEnabled()
            return
        }
        
        self.sharedOutlet.captureDelegate?.didPressCaptureButton(self)
    }
    
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){
        
        if self.composeTabActive == false {
            self.enableCaptureButtn()
            return // release does not correspond to a capture
        }
        
        self.sharedOutlet.captureDelegate?.didReleaseCaptureButton(self)
    }
    

    func enableCaptureButtn(){
        let image = UIImage(named: "Oval 1")
        self.captureButton.setImage(image, forState: .Normal)
        self.composeTabActive = true
    }
    
    func disableCaptureButton(){
        // just left middle
        let image = UIImage(named: "Oval 1-disabled")
        self.captureButton.setImage(image, forState: .Normal)
        self.composeTabActive = false
    }
    
    // MARK: - Navigation
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    
    

}
