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
    func didReleaseCaptureButton(sender: InitViewController) -> [VerseInfo]
}

class InitViewController: UIViewController, UIScrollViewDelegate, AKPickerViewDataSource, AKPickerViewDelegate {

    @IBOutlet var captureButton: UIButton!
    @IBOutlet var captureIcon: UIImageView!
    @IBOutlet var pickerView: AKPickerView!
    @IBOutlet var actionScrollView: UIScrollView!

    var ocrVC: CaptureViewController? = nil
    var scriptVC: ScriptComposeViewController? = nil
    var captureDelegate: CaptureButtonDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // entered capture tab
    @IBAction func didSPressCaptureButton(sender: AnyObject) {
        
        self.captureIcon.alpha = 0
        self.pickerView.hidden = true

        // decide what to do depending on what state we are in
        self.captureDelegate?.didPressCaptureButton(self)

    }
    
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){
        
        self.captureIcon.alpha = 1
        self.pickerView.hidden = false
        
        // get verses from capture session
        if let verses = self.captureDelegate?.didReleaseCaptureButton(self) {
    
            // pass along to scriptvc
            self.scriptVC?.addVersesToScript(verses)
        }

    }
    

    func enableCaptureButtn(){
        let image = UIImage(named: "Oval 1")
        self.captureButton.setImage(image, forState: .Normal)
    }
    
    func disableCaptureButton(){
        // just left middle
        let image = UIImage(named: "Oval 1-disabled")
        self.captureButton.setImage(image, forState: .Normal)
    }
    
    // MARK: - Navigation
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // going to script
        if segue.identifier == "scriptsegue" {
            if let scriptVC = segue.destinationViewController as? ScriptComposeViewController {
                self.scriptVC = scriptVC
            }
        }
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
