//
//  CaptureViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/8/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class CaptureViewController: UIViewController {

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
    var activeCaptureSession: UInt64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // configure camera
        self.captureView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        
        // setup a temp datasource
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size,
                                                         scriptId: nil,
                                                         ephemeral: true)
        self.captureVerseTable.dataSource = self.tableDataSource
        self.captureVerseTable.isExpanded = false

    }
    

    func configure(size: CGSize){
        self.frameSize = size
    }
    
    // MARK: -CaptureButton Delegate
    func didPressCaptureButton(){
        
        if self.captureLock.tryLock() {
            self.activeCaptureSession = self.session.currentId
            self.view.frame.size = self.frameSize
            self.cam.addCameraBlurTargets(self.captureView)

            self.cam.resume()
            Animations.start(0.3){
                self.view.alpha = 1
            }
            self.startOCRCaptureAction()
            self.captureLock.unlock()
        }

    }
    
    func startOCRCaptureAction(){
        
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
            
    }
    
    func captureLoop(){
        let sessionId = self.session.currentId
        
        // capture frames
        Timing.runAfterBg(2.0) {
            self.cam.ocr.processing = true
            while self.session.currentId == sessionId {
                
                // grap frame from campera
                if let image = self.cam.imageFromFrame(){

                    // do image recognition
                    if let recognizedText = self.cam.processImage(image){
                        self.didProcessFrame(withText: recognizedText, image: image, fromSession: sessionId)
                    }
                }
                
                if (self.session.active == false){
                    self.cam.ocr.processing = false
                    break
                }
            }
        }
    }
    
    
    // MARK: - OCRProcess
    func didProcessFrame(withText text: String, image: UIImage, fromSession: UInt64) {
        
        
        if fromSession != self.activeCaptureSession {
            return // Ignore: from old capture session
        }
        if (text.length == 0){
            self.session.misses += 1
            return // empty
        } else {
            self.session.misses = 0
        }
        
        Animations.fadeOutIn(0.2, tsFadeOut: 0.6, view: self.captureBox, alpha: 0)
        
        updateLock.lock()
        let id = self.captureVerseTable.numberOfSections+1
        
        if let allVerses = TextMatcher().findVersesInText(text) {
            
            for var verseInfo in allVerses {
                if BooksData.sharedInstance.exists(verseInfo.bookNo!,
                                                   chapter: verseInfo.chapterNo!,
                                                   verse: verseInfo.verse!) {
                
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
                                if self.session.active {
                                    self.updateLock.lock()
                                    self.captureVerseTable.addSection()
                                    self.updateLock.unlock()
                                }
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
                }
            }
        }
        
        updateLock.unlock()
        
    }
    
    func didReleaseCaptureButton() -> [VerseInfo] {
        
        if self.activeCaptureSession != session.currentId {
            // session does not correspond with initial button press
            return []
        }

        updateLock.lock()

        var capturedVerses:[VerseInfo] = []

        Animations.start(0.3){
            // fade out the view
            self.view.alpha = 0
        }
        
        // handle release
        let hasNewMatches = self.handleCaptureRelease()
        if hasNewMatches {
            // get captured verses
            if let ds = self.tableDataSource {
                capturedVerses = ds.recentVerses
            }
        }
        
        // clear out the temp table
        self.captureVerseTable.clear()
        
        self.cam.removeTarget(self.captureView)
        updateLock.unlock()

        return capturedVerses
    }
    
    func handleCaptureRelease() -> Bool {
        

        var hasNewMatches = false
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
        
        self.session.newMatches = 0
        self.session.misses = 0
        
        // resort verse table by priority
        self.captureVerseTable.sortByPriority()
        self.captureVerseTable.reloadData()
        self.captureVerseTable.scrollToEnd()
        
        self.session.active = false

        return hasNewMatches
    }

}
