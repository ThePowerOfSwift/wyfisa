//
//  InitViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/11/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage
import AKPickerView_Swift

protocol CaptureButtonDelegate: class {
    func didPressCaptureButton(sender: InitViewController)
    func didReleaseCaptureButton(sender: InitViewController, verses: [VerseInfo]) -> Bool
}

class SharedOutlets {
    static let instance = SharedOutlets()
    weak var captureDelegate:CaptureButtonDelegate?
    var tabBarFrame: CGRect? = nil
    var notifyTabEnabled = notifyCallback
    var notifyTabDisabled = notifyCallback
}

class InitViewController: UIViewController, UIScrollViewDelegate, AKPickerViewDataSource, AKPickerViewDelegate {

    @IBOutlet var captureBoxActive: UIImageView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var captureVerseTable: VerseTableView!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var captureView: GPUImageView!
    @IBOutlet var captureIcon: UIImageView!
    @IBOutlet var pickerView: AKPickerView!
    @IBOutlet var actionScrollView: UIScrollView!

    var ocrVC: CaptureViewController? = nil
    var captureDelegate: CaptureButtonDelegate? = nil
    
    let settings = SettingsManager.sharedInstance
    var session = CaptureSession.sharedInstance
    let db = DBQuery.sharedInstance
    let sharedOutlet = SharedOutlets.instance
    var composeTabActive: Bool = true
    var captureLock = NSLock()
    var updateLock = NSLock()
    var tabVC: TabBarViewController? = nil
    var tableDataSource: VerseTableDataSource? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sharedOutlet.notifyTabDisabled = self.disableCaptureButton
        
        // setup a temp datasource
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size, ephemeral: true)
        self.captureVerseTable.dataSource = self.tableDataSource
        self.captureVerseTable.isExpanded = false
        
        // setup picker view
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.pickerView.font = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedFont = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedTextColor = UIColor.fire()
        self.pickerView.textColor = UIColor.offWhite(1.0)
        self.pickerView.maskDisabled = false
        self.pickerView.reloadData()
        
        // scroll view
         let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.actionScrollView.contentSize = CGSize(width: self.view.frame.width * 3.0,
                                                   height: self.view.frame.height)
        self.actionScrollView.contentOffset.x = 900.0
        self.ocrVC = storyboard.instantiateViewControllerWithIdentifier("ocrvc") as? CaptureViewController
        self.ocrVC?.view.frame.origin.x = 0
        self.ocrVC?.view.alpha = 0
        self.ocrVC?.configure(self.view.frame.size)
        self.actionScrollView.addSubview(self.ocrVC!.view)
        self.captureDelegate = self.ocrVC
        
        
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        print("ASLAN!!")
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
        self.captureIcon.alpha = 0
        self.pickerView.hidden = true
        /*
        Animations.start(0.3){
            let image = UIImage(named: "OvalLarge")
            self.captureButton.setImage(image, forState: .Normal)
            self.captureView.alpha = 1
            self.captureBoxActive.alpha = 0
            self.captureBox.hidden =  false
            self.captureVerseTable.hidden = false
        }*/
        
        // decide what to do depending on what state we are in
        self.captureDelegate?.didPressCaptureButton(self)

    }
    
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){
        
        if self.composeTabActive == false {
            self.enableCaptureButtn()
            return // release does not correspond to a capture
        }
        self.captureIcon.alpha = 1
        self.pickerView.hidden = false
        self.captureDelegate?.didReleaseCaptureButton(self, verses: [])
        
        /*
        Animations.start(0.3){
            self.captureView.alpha = 0
            let image = UIImage(named: "Oval 1")
            self.captureButton.setImage(image, forState: .Normal)
            self.captureVerseTable.hidden = true
            self.captureBox.hidden =  true
            self.captureBoxActive.alpha = 0
        }
        */
        
        /*
        let needsUpdate = self.handleCaptureRelease()

        if needsUpdate == true {
            if let ds = self.tableDataSource {
                self.sharedOutlet.captureDelegate?
                        .didReleaseCaptureButton(self,
                                                 verses: ds.recentVerses)
            }
        }
        
        self.captureVerseTable.clear()
        */

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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // going to script
        print(segue.identifier)
    }
    
    // MARK: - picker view
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        return pickerView.optionDescription(item)
    }

    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        
        let option = pickerView.selectedOption()
        // SLIDE THE BG
        
        switch option {
        case .VerseOCR:
            self.captureIcon.image = UIImage(named: "captureicon")
            self.actionScrollView.contentOffset.x = 0.0
        case .Photo:
            self.captureIcon.image = UIImage(named: "Camera")
            self.actionScrollView.contentOffset.x = self.view.frame.width
        }
    }
    
    
    

}
