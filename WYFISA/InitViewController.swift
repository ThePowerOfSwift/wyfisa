//
//  InitViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/11/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class InitViewController: UIViewController {

    var tabVC: TabBarViewController? = nil
    @IBOutlet var captureButton: UIButton!
    let inCaptureMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    func getCaptureVC() -> ViewController? {
        let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
        return selectedVC.captureVC
    }
    
    func getPauseVC() -> ViewController? {
        let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
        return selectedVC.pauseVC
    }
    
    func getScrollPage() -> Int {
        let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
        return selectedVC.activePage
    }
    
    func moveToPage(page: Int){
        let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
        selectedVC.scrollToPage(page)
    }
    
    @IBAction func didSPressCaptureButton(sender: AnyObject) {
        let captureViewActive = self.tabVC?.selectedIndex == 1
            
        if (captureViewActive == false) {
            // move to capture tab
            self.tabVC?.selectedIndex = 1
        }
        
        if self.getScrollPage() == 1 {
            // on pause page
            // so move to active
            self.moveToPage(0)
        }
        // get capture vc
        if  let vc = self.getCaptureVC(){
            vc.doCaptureAction()
        }

    }
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){

        var didCaptureVerses = false
        if let vc = self.getCaptureVC() {
            didCaptureVerses = vc.handleCaptureEnd()
        }

        if didCaptureVerses == true {
            // swipe to pause vc
            self.moveToPage(1)
        }

    }
    
    // MARK: - Navigation
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destVC = segue.destinationViewController
        self.tabVC = destVC as! TabBarViewController
    }
    

}
