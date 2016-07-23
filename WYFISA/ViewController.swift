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
    
    func clearCache() {
        DBQuery.sharedInstance.clearCache()
    }
    func hasMatches() -> Bool {
        return self.matches != nil
    }
}
class ViewController: UIViewController, CameraManagerDelegate, VerseTableViewCellDelegate, UIScrollViewDelegate {

    @IBOutlet var debugWindow: GPUImageView!
    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var expandButton: UIButton!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var maskView: UIView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var refeshButton: UIButton!
    @IBOutlet var capTut: UILabel!
    @IBOutlet var tutScrollView: UIScrollView!
    @IBOutlet var tutPager: UIPageControl!
    @IBOutlet var tutImage: UIImageView!
    
    
    let stillCamera = CameraManager.sharedInstance
    let db = DBQuery.sharedInstance
    var session = CaptureSession()
    var captureLock = NSLock()
    var updateLock = NSLock()
    var workingText = "Scanning"
    var flashEnabled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.firstLaunchTut()
        
        verseTable.setCellDelegate(self)

        // send camera to live view
        self.checkCameraAccess()
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        self.stillCamera.addCameraTarget(self.filterView)
        // self.stillCamera.addDebugTarget(self.debugWindow)
        
        // camera config
        stillCamera.zoom(1)
        stillCamera.focus(.AutoFocus)
        
        // start capture
        stillCamera.capture()
        stillCamera.delegate = self
        stillCamera.pause()

    }

    @IBAction func handleScreenTap(sender: AnyObject) {
        stillCamera.focus(.AutoFocus)
    }
    
    
    @IBAction func didPressExpandButton(sender: AnyObject) {
        
        self.hideTut()
        
        // expand|shrink table view
        let didExpand = self.verseTable.expandView(self.view.frame.size)
        
        // modify button image to represent state
        var buttonImage = UIImage(named: "chevron-up")
        if didExpand == true {
            self.stillCamera.pause()
            buttonImage = UIImage(named: "chevron-down")
            Animations.start(0.5) {
              self.captureBox.hidden = true
              self.captureButton.alpha = 0
              self.captureBox.alpha = 0
              self.maskView.alpha = 0.8
            }
        } else {
            if flashEnabled {
                
            }
            Animations.start(0.5) {
                self.captureBox.hidden = false
                self.captureButton.alpha = 1
                self.captureBox.alpha = 1
                self.maskView.alpha = 0
            }
        }
        self.setImageForRefreshButton()
        self.expandButton.setImage(buttonImage, forState: .Normal)

    }
    
    func setImageForRefreshButton(){
        
        
        if(self.verseTable.isExpanded){
            self.refeshButton.setImage(UIImage(named: "minus"), forState: .Normal)
            return
        }
        if self.flashEnabled == true {
            self.refeshButton.setImage(UIImage(named: "flash-fire"), forState: .Normal)

        } else {
            self.refeshButton.setImage(UIImage(named: "flash"), forState: .Normal)
        }
    }
    
    @IBAction func didPressRefreshButton(sender: AnyObject) {
        
        if self.verseTable.isExpanded {
            // is minus button so clear
            if captureLock.tryLock(){
                self.session.currentId = 0

                self.verseTable.clear()
                
                // unlock safely after clear operation
                Timing.runAfter(1){
                    self.captureLock.unlock()
                }
            }
        } else {
            // changing flash mode
            self.flashEnabled = !self.flashEnabled

            self.setImageForRefreshButton()
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didPressCaptureButton(sender: AnyObject) {
        
        self.hideTut()
        if self.captureLock.tryLock() {
            
            // camera init
            stillCamera.resume()
            if self.flashEnabled {
                stillCamera.torch(.On)
            }

            // session init
            self.session.active = true
            let sessionId = self.session.currentId
            session.clearCache()

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
        if self.flashEnabled {
            stillCamera.torch(.Off)
        }

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
        
        if let allVerses = TextMatcher().findVersesInText(text) {

            for var verseInfo in allVerses {
                if let verse = self.db.lookupVerse(verseInfo.id){

                    // we have match
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
                    stillCamera.focus(.Locked)
                    self.session.matches?.append(verseInfo.id)
                }
            }
        }
        
        // reload table on main queue
        dispatch_async(dispatch_get_main_queue()) {
            self.verseTable.reloadData()
        }
        if self.session.hasMatches() == false {
            stillCamera.focus(.AutoFocus)
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
    

    func firstLaunchTut(){
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let isAppAlreadyLaunchedOnce = defaults.stringForKey("isAppAlreadyLaunchedOnce"){
            print(isAppAlreadyLaunchedOnce) // was launched
        } else {
            showTut()
            // only set to bool when they've seen forecast page
            defaults.setBool(true, forKey: "isAppAlreadyLaunchedOnce")
        }
        
        self.capTut.hidden = false
        Animations.startAfter(1, forDuration: 0.5){
            self.capTut.alpha = 1
        }
    }

    @IBAction func didSwipeTut(sender: AnyObject) {
    }
    
    func showTut(){
   
        self.tutScrollView.hidden = false
        self.tutPager.hidden = false
        self.tutScrollView.contentSize.width = self.view.frame.size.width * 4.0
        self.tutScrollView.delegate = self
        self.captureButton.hidden = true
        self.captureBox.hidden = true
        self.expandButton.hidden = true
        self.refeshButton.hidden = true
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page =  self.tutScrollView.contentOffset.x/self.view.frame.size.width
        self.tutPager.currentPage = Int(page)
        switch page {
        case 0:
                self.tutImage.alpha = 0
            Animations.start(0.2){
                self.tutImage.alpha = 1
                self.tutImage.image = UIImage.init(named: "Find")
            }

        case 1:
                self.tutImage.alpha = 0
            Animations.start(0.2){
                self.tutImage.alpha = 1
                self.tutImage.image = UIImage.init(named: "Capture")
            }
        case 2:
            self.tutImage.alpha = 0
            Animations.start(0.2){
                self.tutImage.alpha = 1
                self.tutImage.image = UIImage.init(named: "Study")
            }
        default:
            // done
            self.tutScrollView.delegate = self
            self.captureButton.hidden = false
            self.captureBox.hidden = false
            self.expandButton.hidden = false
            self.refeshButton.hidden = false
            Animations.start(0.1){
                self.tutScrollView.alpha = 0
                self.tutScrollView.hidden = true
                self.tutScrollView.delegate = nil
                self.tutPager.hidden = true
            }


        }
    }

    
    func hideTut() {
        Animations.start(0.2){
            self.capTut.hidden = true
        }
    }
    
}


