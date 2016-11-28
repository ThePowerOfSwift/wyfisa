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
    var matches: [String] = [String]()
    var newMatches = 0
    var misses = 0
    
    func clearCache() {
        DBQuery.sharedInstance.clearCache()
    }
    func hasMatches() -> Bool {
        return self.newMatches > 0
    }
}
class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var refeshButton: UIButton!
    @IBOutlet var captureBoxActive: UIImageView!
    
    @IBOutlet var gradientView: UIImageView!
    @IBOutlet var capTut: UILabel!
    @IBOutlet var trashIcon: UIButton!
    
    let db = DBQuery.sharedInstance
    let themer = WYFISATheme.sharedInstance
    let settings = SettingsManager.sharedInstance
    var cam = CameraManager.sharedInstance

    var session = CaptureSession()
    var captureLock = NSLock()
    var updateLock = NSLock()
    var workingText = "Scanning"
    var settingsEnabled: Bool = false
    var nightEnabled: Bool = false
    var firstLaunch: Bool = false
    var lastCaptureEmpty: Bool = false
    var isExpanded: Bool = false
    var tableDataSource: VerseTableDataSource? = nil
    var frameSize: CGSize? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.verseTable.dataSource = self.tableDataSource
        self.verseTable.isExpanded = self.isExpanded
    }
    
    func configure(dataSource: VerseTableDataSource, isExpanded: Bool, size: CGSize){
        self.tableDataSource = dataSource
        self.isExpanded = isExpanded
        self.view.frame.size = size
        self.frameSize = size
    }
    
    func initCamera(){
        
        if self.firstLaunch == false {
            return
        }
        
        self.firstLaunch = false

        // send camera to live view
        self.checkCameraAccess()

        // camera config
        self.cam.zoom(1)
        self.cam.focus(.ContinuousAutoFocus)

    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.verseTable.reloadData()
        
        if self.firstLaunch == false {
            self.firstLaunch = true
            print(self.isExpanded)
            if self.isExpanded == false {
                self.initCamera()
            }
        } else {
            self.capTut.hidden = false
        }
        if let size = self.frameSize {
            self.view.frame.size = size
        }
        
        if self.isExpanded == true {
            self.captureBox.hidden = true
           // self.searchBar.hidden = false
            self.trashIcon.hidden = false
           // self.searchBarBG.hidden = false
            self.gradientView.hidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func doCaptureAction(){
        if self.captureLock.tryLock() {

            self.cam.resume()
            
            // show capture box
            self.captureBoxActive.hidden = false
            self.captureBox.hidden = false

            
            //self.verseTable.isExpanded = false
            self.verseTable.reloadData()
            self.verseTable.setContentToCollapsedEnd()
            
            // flash capture box
            Animations.fadeOutIn(0.3, tsFadeOut: 0.3, view: self.captureBox, alpha: 0)

            
            if self.settings.useFlash == true {
                self.cam.torch(.On)
            }
            
            // session init
            self.session.active = true
            session.clearCache()
            
            // adds row to verse table
            let defaultVerse = VerseInfo(id: "", name: self.workingText, text: "")
            self.tableDataSource?.appendVerse(defaultVerse)
            self.verseTable.addSection()
 
 
            
            Timing.runAfter(0.2){
                self.verseTable.scrollToEnd()
            }
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
    

    func handleCaptureEnd() -> Bool {
        
        var hasNewMatches = false
        updateLock.lock()
        
        
        if self.settings.useFlash == true {
            self.cam.torch(.Off)
        }
        
        // remove scanning box
        if self.session.newMatches == 0 && self.session.active {
            self.verseTable.removeFailedVerse()
        } else {
            hasNewMatches = true
        }
        
        // hide capture box
        self.captureBoxActive.hidden = true

        
        self.updateCaptureId()
        self.session.newMatches = 0
        self.session.active = false
        self.session.misses = 0
        
        // resort verse table by priority
        self.verseTable.sortByPriority()
        self.verseTable.setContentToExpandedEnd()

        updateLock.unlock()
        return hasNewMatches
    }
    
    // updates and returns old id
    func updateCaptureId() -> UInt64 {
        let currId = self.session.currentId
        self.session.currentId = currId + 1
        return currId
    }
    
    // MARK: - Process
    
    // when frame has been processed we need to write it back to the cell
    func didProcessFrame(withText text: String, image: UIImage, fromSession: UInt64) {
        
        // print(text)
        if fromSession != self.session.currentId {
            return // Ignore: from old capture session
        }
        if (text.length == 0){
            self.session.misses += 1
            return // empty
        } else {
            self.session.misses = 0
        }
        
        Animations.fadeOutIn(0.3, tsFadeOut: 0.3, view: self.captureBox, alpha: 0)


        updateLock.lock()

        
        
        let id = self.verseTable.numberOfSections+1 // was nVerses+1
        if let allVerses = TextMatcher().findVersesInText(text) {

            for var verseInfo in allVerses {
                
                if let verse = self.db.lookupVerse(verseInfo.id){

                    // we have match
                    verseInfo.text = verse
                    verseInfo.session = fromSession
                    verseInfo.image = image

                    self.verseTable.updateVersePriority(verseInfo.id, priority: verseInfo.priority)
                    
                    // make sure not repeat match
                    if self.session.matches.indexOf(verseInfo.id) == nil {

                        // notify
                        Animations.fadeInOut(0, tsFadeOut: 0.3, view: self.captureBoxActive, alpha: 0.6)
                        
                        // first match replaces scanning icon
                        if self.session.newMatches == 0 {
                            self.verseTable.updateVerseAtIndex(id-1, withVerseInfo: verseInfo)
                        } else {
                            // new match
                            self.tableDataSource?.appendVerse(verseInfo)
                            dispatch_async(dispatch_get_main_queue()) {
                                self.verseTable.addSection()
                            }
                        }
                        
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

    func updateSessionMatches(){
        self.session.matches = self.verseTable.currentMatches()
    }
    
    func syncWithDataSource(){
        print(self.session.currentId)
        self.updateSessionMatches()
        if self.session.matches.count == 0 && self.session.currentId > 0 {
            self.verseTable.clear()
            self.session.currentId = 0
        }
    }

     // MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // make sure tutorial is gone if we're pressing buttons!
        self.capTut.hidden = true
        
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


