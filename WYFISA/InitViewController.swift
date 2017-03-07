//
//  InitViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/11/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

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

class InitViewController: UIViewController {

    @IBOutlet var captureBoxActive: UIImageView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var captureVerseTable: VerseTableView!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var pageController: UIPageControl!
    @IBOutlet var captureView: GPUImageView!
    
    let cam = CameraManager.sharedInstance
    let settings = SettingsManager.sharedInstance
    var session = CaptureSession.sharedInstance
    let db = DBQuery.sharedInstance
    let sharedOutlet = SharedOutlets.instance
    var composeTabActive: Bool = true
    var captureLock = NSLock()
    var updateLock = NSLock()
    var tabVC: TabBarViewController? = nil
    var tableDataSource: VerseTableDataSource? = nil
    var workingText = "Scanning"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sharedOutlet.notifyTabDisabled = self.disableCaptureButton
        
        self.captureView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addCameraBlurTargets(self.captureView)
        
        self.cam.zoom(1)
        self.cam.focus(.ContinuousAutoFocus)
        self.captureView.alpha = 0
        self.cam.start()

        // setup a temp datasource
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size, ephemeral: true)
        self.captureVerseTable.dataSource = self.tableDataSource
        self.captureVerseTable.isExpanded = false
        
    }
    
    override func viewDidAppear(animated: Bool) {
        self.cam.pause()
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
        self.cam.resume()

        Animations.start(0.3){
            let image = UIImage(named: "OvalLarge")
            self.captureButton.setImage(image, forState: .Normal)
            self.captureView.alpha = 1
            self.captureBoxActive.alpha = 0
            self.captureBox.hidden =  false
            self.captureVerseTable.hidden = false
        }
        
        // decide what to do depending on what state we are in
        self.sharedOutlet.captureDelegate?.didPressCaptureButton(self)

        self.startOCRCaptureAction()
    }
    
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject){
        
        if self.composeTabActive == false {
            self.enableCaptureButtn()
            return // release does not correspond to a capture
        }
        self.cam.pause()

        Animations.start(0.3){
            self.captureView.alpha = 0
            let image = UIImage(named: "Oval 1")
            self.captureButton.setImage(image, forState: .Normal)
            self.captureVerseTable.hidden = true
            self.captureBox.hidden =  true
            self.captureBoxActive.alpha = 0
        }
        let needsUpdate = self.handleCaptureRelease()

        if needsUpdate == true {
            if let ds = self.tableDataSource {
                self.sharedOutlet.captureDelegate?
                        .didReleaseCaptureButton(self,
                                                 verses: ds.recentVerses)
            }
        }
        
        self.captureVerseTable.clear()

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
    



    // MARK: -Recognition Overlay
    func startOCRCaptureAction(){
        if self.captureLock.tryLock() {
            
            // show working text
            let defaultVerse = VerseInfo(id: "", name: self.workingText, text: "")
            self.tableDataSource?.appendVerse(defaultVerse)
            self.captureVerseTable.addSection()
            
            // flash capture box
            Animations.fadeOutIn(0.3, tsFadeOut: 0.3, view: captureBox, alpha: 0)
            
            if self.settings.useFlash == true {
                self.cam.torch(.On)
            }
            
            // session init
            self.session.active = true
            session.clearCache()
            
            // start capture loop
            self.captureLoop()
            
            self.captureLock.unlock()
        }
    }
    
    func captureLoop(){
        let sessionId = self.session.currentId
        
        // capture frames
        Timing.runAfterBg(0) {
            while self.session.currentId == sessionId {
                // grap frame from campera
                
                if let image = self.cam.imageFromFrame(){
                    
                    // do image recognition
                    if let recognizedText = self.cam.processImage(image){
                        self.didProcessFrame(withText: recognizedText, image: image, fromSession: sessionId)
                    }
                }
                
                if (self.session.misses >= 10) {
                    self.session.misses = 0
                    break
                }
            }
            Timing.runAfterBg(2.0){
                if (self.session.active == true){
                    self.captureLoop()
                }
            }
        }
        
        
        
    }
    
   
    
    // MARK: - Process
    
    // when frame has been processed we need to write it back to the cell
    func didProcessFrame(withText text: String, image: UIImage, fromSession: UInt64) {
        
        
        if fromSession != self.session.currentId {
            return // Ignore: from old capture session
        }
        if (text.length == 0){
            self.session.misses += 1
            return // empty
        } else {
            self.session.misses = 0
        }
        
        print(text)
        Animations.fadeOutIn(0.3, tsFadeOut: 0.3, view: self.captureBox, alpha: 0)
        
        updateLock.lock()
        let id = self.captureVerseTable.numberOfSections+1
        
        if let allVerses = TextMatcher().findVersesInText(text) {
            
            for var verseInfo in allVerses {
                
    //            if let verse = self.db.lookupVerse(verseInfo.id){
                    
                    // we have match
                    verseInfo.text = "" //verse
                    verseInfo.session = fromSession
                    verseInfo.image = image
                    
                    
                    // make sure not repeat match
                    if self.session.matches.indexOf(verseInfo.id) == nil {
                        
                        // notify
                        Animations.fadeInOut(0, tsFadeOut: 0.3, view: self.captureBoxActive, alpha: 0.6)
                        
                        // new match
                        if self.session.newMatches == 0 {
                            self.captureVerseTable.updateVerseAtIndex(id-1, withVerseInfo: verseInfo)
                        } else {
                            self.tableDataSource?.appendVerse(verseInfo)
                            dispatch_async(dispatch_get_main_queue()) {
                                self.captureVerseTable.addSection()
                            }
                        }
                        self.captureVerseTable.updateVersePriority(verseInfo.id, priority: verseInfo.priority)
                        
                        // cache
                        self.db.chapterForVerse(verseInfo.id)
                        self.db.crossReferencesForVerse(verseInfo.id)
                        self.db.versesForChapter(verseInfo.id)
                        
                    } else {
                        // dupe
                        continue
                    }
                    
                    self.session.newMatches += 1
                    self.session.matches.append(verseInfo.id)
//                }
            }
        }
        
        updateLock.unlock()
        
    }
    
    
    func handleCaptureRelease() -> Bool {
        
        var hasNewMatches = false
        updateLock.lock()
        Timing.runAfter(0.3){
            self.captureBox.alpha = 1.0 // make sure capture box stays enabled
        }
        
        if self.settings.useFlash == true {
            self.cam.torch(.Off)
        }
        
        // remove scanning box
        if self.session.newMatches > 0 && self.session.active {
            hasNewMatches = true
        }
        
        // update session
        self.session.updateCaptureId()
        
        self.session.newMatches = 0
        self.session.active = false
        self.session.misses = 0
        
        // resort verse table by priority
        self.captureVerseTable.sortByPriority()
        self.captureVerseTable.reloadData()
        self.captureVerseTable.scrollToEnd()
        
        
        updateLock.unlock()
        return hasNewMatches
    }
    
    

}
