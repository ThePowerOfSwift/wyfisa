//
//  HistoryViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/22/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage
import AKPickerView_Swift

class HistoryViewController: UIViewController, AKPickerViewDataSource, AKPickerViewDelegate  {

    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var captureImage: GPUImageView!
    @IBOutlet var captureContainer: UIView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var captureBoxActive: UIImageView!
    @IBOutlet var pickerView: AKPickerView!
    @IBOutlet var photoImageView: GPUImageView!

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
            self.view.frame.size.height = size.height*0.85
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
        // check camera permissions
        self.checkCameraAccess()
        if self.cameraEnabled { // start
            self.cam.start()
            self.cam.zoom(1)
            self.cam.focus(.ContinuousAutoFocus)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.themeView()
        
        // setup camera
        self.captureImage.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addTarget(self.captureImage)
        
        self.photoImageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addTarget(self.photoImageView)
        
        // setup picker view
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.pickerView.font = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedFont = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedTextColor = UIColor.fire()
        self.pickerView.selectItem(1)
        self.pickerView.maskDisabled = false
        self.pickerView.reloadData()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressClearButton(sender: AnyObject) {
        
        // toggle editing mode
        self.isEditingMode = !self.isEditingMode

        // update editing state
        self.verseTable.setEditing(self.isEditingMode, animated: true)
        
        if self.isEditingMode == true {
            // hide capture container if showing
            self.pickerView.selectItem(0, animated: true)
        }
    }

    
    
    func exitEditingMode(){
        if self.verseTable.editing == true {
            self.verseTable.setEditing(false, animated: true)
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
            
            // update editing state
            self.verseTable.setEditing(self.isEditingMode, animated: true)
        }
    }

    // MARK: - Capture management    
    func updateSessionMatches(){
        self.session.matches = self.verseTable.currentMatches()
    }
    
    func syncWithDataSource(){
        self.updateSessionMatches()
        if self.session.matches.count == 0 && self.session.currentId > 0 {
            self.verseTable.clear()
            self.session.currentId = 0
        }
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
        
        // only do ocr-mode if in verse detection
        if self.pickerView.selectedItem == 2 {
            self.startOCRCaptureAction()
        }
        if self.pickerView.selectedItem == 0 {
            // scroll to end
            self.verseTable.scrollToEnd()
        }
    }
    
    func startOCRCaptureAction(){
        if self.captureLock.tryLock() {
            
            self.verseTable.isExpanded = false
            self.verseTable.reloadData()
            
            self.captureBox.alpha = 1.0
            
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
        
        if self.pickerView.selectedItem == 0 {
            return true // nothing to do
        }
        
        var hasNewMatches = false
        updateLock.lock()
        self.captureBox.alpha = 0.0

        self.verseTable.isExpanded = true
        
        if self.settings.useFlash == true {
            self.cam.torch(.Off)
        }
        
        // remove scanning box
        if self.session.newMatches > 0 && self.session.active {
            hasNewMatches = true
        }
        
        // update session
        self.updateCaptureId()
        
        // add last image to list if in photo mode
        if self.pickerView.selectedItem == 1 {
            let verseInfo = VerseInfo.init(id: "0", name: "", text: nil)
            verseInfo.session = self.session.currentId
            verseInfo.category = .Image
            let captureImage =  self.cam.imageFromFrame()
            verseInfo.image = captureImage
            verseInfo.accessoryImage = captureImage
            self.tableDataSource?.appendVerse(verseInfo)
            
            // add the section to capture table and then reload pauseVC
            dispatch_async(dispatch_get_main_queue()) {
                self.verseTable.addSection()
            }
            
            // TODO - adjust by settings if we want to hide after photo
            self.pickerView.selectItem(0, animated: true)
        }
        
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
                        continue
                    }
                    
                    self.session.newMatches += 1
                    self.session.matches.append(verseInfo.id)
                }
            }
        }
        
        updateLock.unlock()
        
    }

    
    // MARK: - picker view
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return 3
    }
    
    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        switch item {
        case 0:
            return "HIDE"
        case 1:
            return "PHOTO"
        case 2:
            return "VERSE DETECTION"
        default:
            return ""
        }
    }
    
    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        let hide = {
            switch item {
            case 0: // hide all
                self.photoImageView.alpha = 0.0
                self.captureAssetsAlpha(0.0)
                self.hideCaptureContainer(true)
                
                // pause camera
                self.cam.pause()
            case 1: // hide capture
                self.captureAssetsAlpha(0.0)
            case 2: // hide photo
                self.photoImageView.alpha = 0.0
            default:
                break
            }
        }
        let show = {
            switch item {
            case 0: // show all
                break
            case 1: // show photo
                self.hideCaptureContainer(false)
                self.photoImageView.alpha = 1.0
                self.resumeCam()
            case 2: // show capture
                self.hideCaptureContainer(false)
                self.captureImage.alpha = 1.0 // only showing image, box activated on press
                self.resumeCam()
            default:
                break
            }
        }
        
        // hide then show active item
        Animations.start(0.3, animations: hide)
        Animations.startAfter(0.3, forDuration: 0.3, animations: show)

    }
    
    func captureAssetsAlpha(alpha: CGFloat) {
        self.captureImage.alpha = alpha
        self.captureBox.alpha = alpha
    }
    
    func hideCaptureContainer(hidden: Bool){
        self.captureContainer.hidden = hidden
    }
    
    func resumeCam(){
        if self.cam.state == .Paused {
            self.cam.resume()
        }
    }

    @IBAction func didSwipePickerView(sender: UISwipeGestureRecognizer) {
        var selectedItem = self.pickerView.selectedItem

        if sender.direction == .Right && selectedItem > 0 {
            selectedItem -= 1
            Animations.start(0.30){
                self.pickerView.scrollToItem(selectedItem)
            }
            self.pickerView.selectItem(selectedItem)
        }
        if sender.direction == .Left && selectedItem < 2 {
            selectedItem += 1
            Animations.start(0.30){
                self.pickerView.scrollToItem(selectedItem)
            }
            self.pickerView.selectItem(selectedItem)

        }
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
