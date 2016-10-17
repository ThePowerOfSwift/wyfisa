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
    


    func toggleCapture(){
        // then toggle expanded view
        let selectedVC = self.tabVC?.selectedViewController as! ViewController
        if selectedVC.captureBox.hidden == true {
            selectedVC.doCaptureAction()
        } else {
            selectedVC.handleCaptureEnd()
        }
    }
    @IBAction func didSPressCaptureButton(sender: AnyObject) {
        if (self.tabVC?.selectedIndex == 1){
            self.toggleCapture()
        }
    }
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){
        if (self.tabVC?.selectedIndex != 1){
            self.tabVC?.selectedIndex = 1
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destVC = segue.destinationViewController
        self.tabVC = destVC as! TabBarViewController
    }
    

}
