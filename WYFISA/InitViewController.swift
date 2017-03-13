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

class InitViewController: UIViewController, UIScrollViewDelegate, AKPickerViewDataSource, AKPickerViewDelegate, UITextFieldDelegate {

    @IBOutlet var captureButton: UIButton!
    @IBOutlet var pickerView: AKPickerView!
    @IBOutlet var actionScrollView: UIScrollView!
    @IBOutlet var fxView: UIVisualEffectView!
    @IBOutlet var scriptTitle: UITextField!
    
    var ocrVC: CaptureViewController? = nil
    var scriptVC: ScriptComposeViewController? = nil
    var photoVC: PhotoCaptureViewController? = nil
    var captureDelegate: CaptureButtonDelegate? = nil
    var activeScriptId: String? = nil
    var activeScript: UserScript? = nil
    let storage = CBStorage.init(databaseName: SCRIPTS_DB, skipSetup: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup picker view
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.pickerView.font = UIFont.systemFontOfSize(15, weight: UIFontWeightBold)
        self.pickerView.highlightedFont = UIFont.systemFontOfSize(12, weight: UIFontWeightBold)
        self.pickerView.highlightedTextColor = UIColor.fire()
        self.pickerView.textColor = UIColor.offWhite(1.0)
        self.pickerView.maskDisabled = false
        self.pickerView.reloadData()
        
        // add vc's to scroll view
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.actionScrollView.contentSize = CGSize(width: self.view.frame.width * 3.0,
                                                   height: self.view.frame.height)
        self.actionScrollView.contentOffset.x = 0
        
        // ocr
        self.ocrVC = storyboard.instantiateViewControllerWithIdentifier("ocrvc") as? CaptureViewController
        self.ocrVC?.view.frame.origin.x = 0
        self.ocrVC?.view.alpha = 0
        self.ocrVC?.configure(self.view.frame.size)
        self.actionScrollView.addSubview(self.ocrVC!.view)
        
        // photo
        self.photoVC = storyboard.instantiateViewControllerWithIdentifier("photocapturevc") as? PhotoCaptureViewController
        self.photoVC?.view.frame.origin.x = self.view.frame.width
        self.photoVC?.view.alpha = 0
        self.photoVC?.configure(self.view.frame.size)
        self.actionScrollView.addSubview(self.photoVC!.view)

        // text field
        self.scriptTitle.delegate = self
        
        // get script doc
        if let script = self.storage.getScriptDoc(self.activeScriptId!) {
            self.activeScript = script
            if (script.title != DEFAULT_SCRIPT_NAME)  && (script.title != "") {
                self.scriptTitle.text = script.title
            }
        }
        
        // start and pause camera
        CameraManager.sharedInstance.start()
        CameraManager.sharedInstance.pause()
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // entered capture tab
    @IBAction func didSPressCaptureButton(sender: AnyObject) {
        
        self.pickerView.hidden = true
        self.fxView.hidden = true
        
        // transition to larger button
        let largeButton = UIImage.init(named: "OvalLarge")
        self.captureButton.setImage(largeButton, forState: .Normal)
        
        // decide what to do depending on what state we are in
        let option = pickerView.selectedOption()

        switch option {
        case .VerseOCR:
            self.actionScrollView.contentOffset.x = 0
            self.ocrVC?.didPressCaptureButton()
        case .Photo:
             self.actionScrollView.contentOffset.x = self.view.frame.width
            self.photoVC?.didPressCaptureButton()
        }
        
    }
    
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){
        
        self.pickerView.hidden = false
        self.fxView.hidden = false

        let normalButton = UIImage.init(named: "OvalSmall")
        self.captureButton.setImage(normalButton, forState: .Normal)

        // decide what to do depending on what state we are in
        let option = pickerView.selectedOption()
        
        switch option {
        case .VerseOCR:
            // get verses from capture session
            if let verses = self.ocrVC?.didReleaseCaptureButton() {
                
                // pass along to scriptvc
                self.scriptVC?.addVersesToScript(verses)
            }
        case .Photo:
            if let photoVerse = self.photoVC?.didReleaseCaptureButton() {
                self.scriptVC?.addVersesToScript([photoVerse])
            }
        }
        // make sure camera is stopped
        CameraManager.sharedInstance.pause()
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
        return HIDE_STATUS_BAR
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // save embedded vcs for accessing later
        
        // compose vc
        if segue.identifier == "scriptsegue" {
            if let svc = segue.destinationViewController as? ScriptComposeViewController {
                self.scriptVC = svc
                svc.scriptId = self.activeScriptId!
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
        
        Animations.fadeOutIn(0.1, tsFadeOut: 0.3, view: self.pickerView, alpha: 0.2)
        self.pickerView.reloadData()
        
    }
    
    // MARK: - text field
    func textFieldDidEndEditing(textField: UITextField) {
        if let title = textField.text {
            self.storage.updateScriptTitle(self.activeScriptId!, title: title)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    

}
