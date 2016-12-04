//
//  HistoryViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/22/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class HistoryViewController: UIViewController {

    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var clearAllButton: UIButton!
    @IBOutlet var captureImage: GPUImageView!
    @IBOutlet var captureContainer: UIView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var captureBoxActive: UIImageView!
    
    let themer = WYFISATheme.sharedInstance
    let cam = CameraManager.sharedInstance
    let settings = SettingsManager.sharedInstance
    let db = DBQuery.sharedInstance

    var tableDataSource: VerseTableDataSource? = nil
    var frameSize: CGSize? = nil
    var isEditingMode: Bool = false
    var cameraEnabled: Bool = true
    var workingText = "Scanning"
    var session = CaptureSession()
    var captureLock = NSLock()
    var updateLock = NSLock()


    
    func configure(dataSource: VerseTableDataSource, isExpanded: Bool, size: CGSize){
        self.tableDataSource = dataSource
        self.view.frame.size = size
        self.frameSize = size
    }
    
    override func viewDidAppear(animated: Bool) {
        self.verseTable.dataSource = self.tableDataSource
        self.verseTable.isExpanded = true
        self.verseTable.reloadData()

        if let size = self.frameSize {
            self.view.frame.size = size
            self.view.frame.size.height = size.height*0.80
        }
        
        self.updateSessionMatches()
        if let ds = self.tableDataSource {
            self.session.currentId = UInt64(ds.nVerses+1)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.verseTable.reloadData()
        self.initCamera()


        if let size = self.frameSize {
            self.view.frame.size = size
        }
    }
    
    func initCamera(){
        // send camera to live view
        self.checkCameraAccess()
        
        // camera config
        self.cam.zoom(1)
        self.cam.focus(.ContinuousAutoFocus)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.themeView()
        
        // setup camera
        self.captureImage.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addTarget(self.captureImage)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateIconsForEditingMode(mode: Bool){
        var fireButton: UIImage? = nil
        if mode == true {
            // entering editing mode
            fireButton = UIImage.init(named: "ios7-minus-fire")
            Animations.start(0.3){
                self.clearAllButton.alpha = 1
            }
        } else {
            fireButton = UIImage.init(named: "ios7-minus")
            Animations.start(0.3){
                self.clearAllButton.alpha = 0
            }
        }
        self.clearButton.setImage(fireButton, forState: .Normal)
    }
    
    @IBAction func didPressClearButton(sender: AnyObject) {
        
        // toggle editing mode
        self.isEditingMode = !self.isEditingMode
        self.updateIconsForEditingMode(self.isEditingMode)

        // update editing state
        self.verseTable.setEditing(self.isEditingMode, animated: true)
    }
    
    @IBAction func didPressClearAllButton(sender: AnyObject) {
        self.isEditingMode = false
        self.verseTable.setEditing(self.isEditingMode, animated: true)
        
        // empty table
        self.verseTable.clear()
        self.updateIconsForEditingMode(false)
        
        self.updateSessionMatches()
        // notify parents
        self.verseTable.reloadData()

    }
    
    
    func exitEditingMode(){
        if self.verseTable.editing == true {
            self.verseTable.setEditing(false, animated: true)
            self.updateIconsForEditingMode(false)
        }
    }
    
    func themeView(){
        // bg color
        self.view.backgroundColor = themer.whiteForLightOrNavy(1.0)
    }
    
    @IBAction func didPanRight(sender: AnyObject) {
    
        if self.isEditingMode == false {
            // toggle editing mode
            self.isEditingMode = !self.isEditingMode
            self.updateIconsForEditingMode(self.isEditingMode)
            
            // update editing state
            self.verseTable.setEditing(self.isEditingMode, animated: true)
        }
    }
    
    

    
    // MARK: - Capture management
    
    func updateSessionMatches(){
        self.session.matches = self.verseTable.currentMatches()
    }
    
    func checkCameraAccess() {
        
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) !=  AVAuthorizationStatus.Authorized
        {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == false
                {
                   self.cameraEnabled = false
                }
            });
        }
    }
    
    func startCaptureAction(){
        if self.captureLock.tryLock() {
            
            self.verseTable.isExpanded = false
            self.verseTable.reloadData()
            
            self.cam.resume()
            
            Animations.start(0.1){
                self.captureContainer.hidden = false
            }
            Timing.runAfter(0){
                self.verseTable.scrollToEnd()
            }
            
            // flash capture box
            Animations.fadeOutIn(0.3, tsFadeOut: 0.3, view: self.captureBox, alpha: 0)
            
            if self.settings.useFlash == true {
                self.cam.torch(.On)
            }
            
            // session init
            self.session.active = true
            session.clearCache()
    
            
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
    
    
    func endCaptureAction() -> Bool {
        
        var hasNewMatches = false
        updateLock.lock()
        self.verseTable.isExpanded = true

        // hide capture container
        Animations.start(0.1){
            self.captureContainer.hidden = true
        }
        self.cam.pause()
        
        if self.settings.useFlash == true {
            self.cam.torch(.Off)
        }
        
        // remove scanning box
        if self.session.newMatches > 0 && self.session.active {
            hasNewMatches = true
        }
        
        
        self.updateCaptureId()
        self.session.newMatches = 0
        self.session.active = false
        self.session.misses = 0
        
        // resort verse table by priority
        self.verseTable.sortByPriority()
        self.verseTable.reloadData()
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
        
        print(text)
        
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
                    
                    
                    // make sure not repeat match
                    if self.session.matches.indexOf(verseInfo.id) == nil {
                        
                        // notify
                        Animations.fadeInOut(0, tsFadeOut: 0.3, view: self.captureBoxActive, alpha: 0.6)
                        
                        // new match
                        self.tableDataSource?.appendVerse(verseInfo)
                        dispatch_async(dispatch_get_main_queue()) {
                            self.verseTable.addSection()
                            self.verseTable.updateVersePriority(verseInfo.id, priority: verseInfo.priority)

                        }
                
                        
                        // cache
                        self.db.chapterForVerse(verseInfo.id)
                        self.db.crossReferencesForVerse(verseInfo.id)
                        self.db.versesForChapter(verseInfo.id)
                        
                    } else {
                        // dupe
                        print("NO DUPE LYFE")
                        continue
                    }
                    
                    self.session.newMatches += 1
                    self.session.matches.append(verseInfo.id)
                }
            }
        }
        
        updateLock.unlock()
        
    }


}


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
