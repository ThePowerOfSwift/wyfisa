//
//  ViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

struct CaptureSession {
    var active: Bool = false
    var currentId: UInt64 = 0
    var matches: [String]?

    func hasMatches() -> Bool {
        return self.matches != nil
    }
}
class ViewController: UIViewController, CameraManagerDelegate, VerseTableViewCellDelegate {

    @IBOutlet var debugWindow: GPUImageView!
    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var expandButton: UIButton!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var maskView: UIView!
    @IBOutlet var captureBox: UIImageView!
    
    
    let stillCamera = CameraManager.sharedInstance
    let db = DBQuery.sharedInstance
    var session = CaptureSession()
    var captureLock = NSLock()
    var updateLock = NSLock()
    var workingText = "Searching"

    override func viewDidLoad() {
        super.viewDidLoad()
        verseTable.setCellDelegate(self)
        
        self.checkCameraAccess()

        // send camera to live view
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        self.stillCamera.addCameraTarget(self.filterView)
        // self.stillCamera.addDebugTarget(self.debugWindow)
        
        // camera config
        stillCamera.zoom(1.5)
        stillCamera.focus(.AutoFocus)
        

        // start capture
        stillCamera.capture()
        stillCamera.delegate = self
        

    }
    

    @IBAction func handleScreenTap(sender: AnyObject) {
        stillCamera.focus(.AutoFocus)
    }
    
    
    @IBAction func didPressExpandButton(sender: AnyObject) {
        
        // expand|shrink table view
        let didExpand = self.verseTable.expandView(self.view.frame.size)
        
        // modify button image to represent state
        var buttonImage = UIImage(named: "arrow-expand")
        if didExpand == true {
            self.stillCamera.pause()
            buttonImage = UIImage(named: "arrow-expand-blue")

            Animations.start(0.5) {
              self.captureBox.hidden = true
              self.captureButton.alpha = 0
              self.captureBox.alpha = 0
              self.maskView.alpha = 0.8
            }
        } else {
            Animations.start(0.5) {
                self.captureBox.hidden = false
                self.captureButton.alpha = 1
                self.captureBox.alpha = 1
                self.maskView.alpha = 0
            }
        }
        self.expandButton.setImage(buttonImage, forState: .Normal)

    }
    
    
    @IBAction func didPressRefreshButton(sender: AnyObject) {
        if captureLock.tryLock(){
            self.session.currentId = 0

            self.verseTable.clear()
            
            // unlock safely after clear operation
            Timing.runAfter(1){
                self.captureLock.unlock()
            }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didPressCaptureButton(sender: AnyObject) {
        
        
        if self.captureLock.tryLock() {
            stillCamera.resume()
            stillCamera.focus(.AutoFocus)
            
            /*
            if  self.session.currentId  == 0 {
                // establish initial focus
                self.stillCamera.focus(.AutoFocus)
            }
 

            self.stillCamera.focus(.Locked)
            */
            
            self.session.active = true
            let sessionId = self.session.currentId

            // adds row to verse table
            let defaultVerse = VerseInfo(id: "", name: self.workingText, text: "")
            self.verseTable.appendVerse(defaultVerse)
            self.verseTable.addSection()
           
            // capture frames
            let asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(asyncQueue) {
                while self.session.currentId == sessionId {
                    self.stillCamera.recognizeFrameFromCamera(sessionId)
                }
            }
            self.captureLock.unlock()
        }
        
    }

    func handleCaptureEnd(){
        updateLock.lock()
        stillCamera.pause()

        self.session.currentId += 1
        
        if self.session.hasMatches() == false && self.session.active {
            self.verseTable.removeFailedVerse()
        }
        self.session.matches = nil
        self.session.active = false
        
        updateLock.unlock()

    }
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject) {
        self.handleCaptureEnd()
    }
    @IBAction func didReleaseCaptureButtonOutside(sender: AnyObject) {
        self.handleCaptureEnd()

    }
    
    // MARK: - CameraManagerDelegate
    
    // when frame has been processed we need to write it back to the cell
    func didProcessFrame(sender: CameraManager, withText text: String, fromSession: UInt64) {
        
        // print(text)
        if fromSession != self.session.currentId {
            return // Ignore: from old capture session
        }
        
        updateLock.lock()
        let id = self.verseTable.numberOfSections
        
        if let allVerses = TextMatcher.findVersesInText(text) {
            // we have detection
            // stillCamera.focus(.Locked)

            for var verseInfo in allVerses {
                if let verse = self.db.lookupVerse(verseInfo.id){

                    verseInfo.text = verse
                    
                    // automatically add first match
                    if self.session.hasMatches() == false {
                        self.verseTable.updateVerseAtIndex(id-1, withVerseInfo: verseInfo)
                        self.session.matches = [String]()
                    } else {
                        // make sure not repeat match
                        if self.session.matches?.indexOf(verseInfo.id) == nil {
                            // new match

                            self.verseTable.appendVerse(verseInfo)
                            dispatch_async(dispatch_get_main_queue()) {
                                self.verseTable.addSection()
                            }
                        } else {
                            updateLock.unlock()
                            return
                        }
                    }
                    self.session.matches?.append(verseInfo.id)
                }
            }
        } else {
            if self.session.hasMatches() == false {
                self.verseTable.updateVersePending(id-1)
            }
        }
        
        // reload table on main queue
        dispatch_async(dispatch_get_main_queue()) {
            self.verseTable.reloadData()
        }
        updateLock.unlock()

    }
    
    // MARK: - Table cell delegate
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo){
        
        performSegueWithIdentifier("VerseDetail", sender: (verse as! AnyObject))
    }

     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
         // pause camera
        dispatch_async(dispatch_get_main_queue()) {
            self.stillCamera.pause()
        }

        
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
        if segue.identifier == "VerseDetail" {
            let toVc = segue.destinationViewController as! VerseDetailModalViewController

            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
        }
     }
 

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func checkCameraAccess() {
        
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) !=  AVAuthorizationStatus.Authorized
        {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == false
                {
                    self.workingText = "Camera Disabled!"
                }
            });
        }
    }
}


