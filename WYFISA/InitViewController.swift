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


class InitViewController: UIViewController {

    @IBOutlet var captureButton: UIButton!
    @IBOutlet var pageController: UIPageControl!
    
    var tabVC: TabBarViewController? = nil
    var inCaptureMode: Bool = false
    weak var delegate:CaptureButtonDelegate?

    
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
        
        self.inCaptureMode = true
        self.delegate?.didPressCaptureButton(self)
    }
    
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){

        
        if self.inCaptureMode == false {
            let image = UIImage(named: "Oval 1")
            self.captureButton.setImage(image, forState: .Normal)
            return // release does not correspond to a capture
        }
        
        self.delegate?.didReleaseCaptureButton(self)
    }
    
    // MARK: - Navigation
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destVC = segue.destinationViewController
        self.tabVC = destVC as! TabBarViewController
        self.tabVC?.applyDelegate(self)
     //   self.tabVC?.onTabChange = self.didChangeTab
     //   self.tabVC?.onPageChange = self.didChangePage

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
