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

    override func viewWillAppear(animated: Bool) {
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            self.tabVC?.selectedIndex = 1
            self.inCaptureMode = false
            let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
            selectedVC.pauseVC?.verseTable.reloadData()
            
            // theme
            selectedVC.pauseVC?.themeView()
            if selectedVC.pauseVC?.pickerView.selectedItem != 0 {
                selectedVC.pauseVC?.resumeCam()
            }
            return // just activate don't start scanning
        }
        
        
        let selectedVC = self.tabVC?.selectedViewController as! ScrollViewController
        if selectedVC.activePage == 0 {
            // correspond to capture
            self.inCaptureMode = true
            if  let vc = self.getPauseVC(){
                vc.startCaptureAction()
            }
        } else {
            // is just a scroll handler for script page
            selectedVC.scriptVC?.scriptCollection.scrollToEnd()
        }

    }
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){

        
        if self.inCaptureMode == false {
            let image = UIImage(named: "Oval 1")
            self.captureButton.setImage(image, forState: .Normal)
            return // release does not correspond to a capture
        }
        
        self.getPauseVC()?.endCaptureAction()

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
            if let vc = self.getPauseVC() {
                vc.cam.pause()
            }
            self.pageController.hidden = true
        }
    }
    
    
    

}
