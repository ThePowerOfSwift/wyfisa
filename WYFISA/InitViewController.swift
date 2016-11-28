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
    var inCaptureMode: Bool = false
    @IBOutlet var pageController: UIPageControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func getCaptureVC() -> ViewController? {
        let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
        return selectedVC.captureVC
    }
    
    func getPauseVC() -> HistoryViewController? {
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
        self.pageController.currentPage = page
    }
    
    // entered capture tab
    @IBAction func didSPressCaptureButton(sender: AnyObject) {
        
        let captureViewActive = self.tabVC?.selectedIndex == 1
            
        if (captureViewActive == false) {
            // move to capture tab
            self.pageController.hidden = false
            
            self.tabVC?.selectedIndex = 1
            self.inCaptureMode = false
            let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
            selectedVC.captureVC?.verseTable.reloadData()
            selectedVC.pauseVC?.verseTable.reloadData()
            if self.getScrollPage() == 0 {
                if let vc = self.getCaptureVC() {
                    vc.cam.resume()
                }
            }
            
            // theme
            selectedVC.pauseVC?.themeView()
            
            return // just activate don't start scanning
        }
        
        self.inCaptureMode = true
        
        if self.getScrollPage() == 1 {
            // move to active
            self.moveToPage(0)
        }
        // get capture vc
        if  let vc = self.getCaptureVC(){
            vc.doCaptureAction()
        }

    }
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){

        if self.inCaptureMode == false {
            let image = UIImage(named: "Oval 1")
            self.captureButton.setImage(image, forState: .Normal)
            return // release does not correspond to a capture
        }
        
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
        return true
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destVC = segue.destinationViewController
        self.tabVC = destVC as! TabBarViewController
        self.tabVC?.onTabChange = self.didChangeTab
        self.tabVC?.onPageChange = self.didChangePage

    }
    
    func didChangePage(page: Int){
        self.pageController.currentPage = page
    }
    
    func didChangeTab(tab: Int){
        
        if (tab == 1) {
            // just left middle
            let image = UIImage(named: "Oval 1-disabled")
            self.captureButton.setImage(image, forState: .Normal)
            // pause camera
            if let vc = self.getCaptureVC() {
                vc.cam.pause()
            }
            self.pageController.hidden = true
        }
    }
    

}
