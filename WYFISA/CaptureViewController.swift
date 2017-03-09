//
//  CaptureViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/8/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class CaptureViewController: UIViewController, CaptureButtonDelegate {

    @IBOutlet var captureBoxActive: UIImageView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var captureVerseTable: VerseTableView!
    @IBOutlet var captureView: GPUImageView!
    
    let cam = CameraManager.sharedInstance
    let settings = SettingsManager.sharedInstance
    var session = CaptureSession.sharedInstance
    var tableDataSource: VerseTableDataSource? = nil
    let db = DBQuery.sharedInstance
    var captureLock = NSLock()
    var updateLock = NSLock()
    var frameSize = CGSize()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // configure camera
        self.captureView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addCameraBlurTargets(self.captureView)
        self.cam.zoom(1)
        self.cam.focus(.ContinuousAutoFocus)
        self.cam.start()
        
        
        // setup a temp datasource
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size, ephemeral: true)
        self.captureVerseTable.dataSource = self.tableDataSource
        self.captureVerseTable.isExpanded = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.view.frame.size = self.frameSize
        self.cam.pause()
    }

    func configure(size: CGSize){
        self.frameSize = size
    }
    
    // MARK: -CaptureButton Delegate
    func didPressCaptureButton(sender: InitViewController){
        self.cam.resume()
        Animations.start(0.3){
            self.view.alpha = 1
        }
        self.startOCRCaptureAction()

    }
    
    func didReleaseCaptureButton(sender: InitViewController, verses: [VerseInfo]) -> Bool {
        self.cam.pause()
        Animations.start(0.3){
            self.view.alpha = 0
        }
        let needsUpdate = self.handleCaptureRelease()
        self.captureVerseTable.clear()

        return needsUpdate
    }
    
    // MARK: -Recognition Overlay
    func startOCRCaptureAction(){
        if self.captureLock.tryLock() {
            
            // show working text
            let defaultVerse = VerseInfo(id: "", name: String.workingText, text: "")
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
    
    
    
    // MARK: - OCRProcess
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
