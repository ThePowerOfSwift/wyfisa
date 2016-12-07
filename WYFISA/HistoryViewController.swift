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

class HistoryViewController: UIViewController, CaptureButtonDelegate, AKPickerViewDataSource, AKPickerViewDelegate  {

    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var captureImage: GPUImageView!
    @IBOutlet var captureContainer: UIView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var captureBoxActive: UIImageView!
    @IBOutlet var pickerView: AKPickerView!
    @IBOutlet var photoImageView: GPUImageView!
    @IBOutlet var gradientMask: UIImageView!
    
    var captureDelegate: CaptureButtonDelegate? = nil
    var scrollViewEscapeMask: UIView!

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
    var navNext = notifyCallback
    
    override func viewDidAppear(animated: Bool) {
 
        
        self.updateSessionMatches()
        if let ds = self.tableDataSource {
            self.session.currentId = UInt64(ds.nVerses+1)
        }
        
        self.verseTable.dataSource = self.tableDataSource
        self.verseTable.isExpanded = true
        self.verseTable.scrollNotifier = self.tableScrollNotifierFunc
        
        self.verseTable.reloadData()

        if self.tableDataSource?.nVerses > 0 {
            // hide picker and show current media
            // allows middle to operate as down button
            self.pickerView.selectItemByOption(.Hide, animated: true)
        } else {
            // show the verse ocr
            self.pickerView.selectItemByOption(.Photo, animated: true)
        }
        
    }
    

    func tableScrollNotifierFunc(){
        if self.pickerView.selectedOption() != .Hide {
            self.pickerView.selectItemByOption(.Hide, animated: true)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.initCamera()
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
        
        // verse table
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size)

        // setup picker view
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.pickerView.font = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedFont = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedTextColor = UIColor.fire()
        self.pickerView.maskDisabled = false
        self.pickerView.reloadData()
        
        
    }

    @IBAction func didTapGradientMask(sender: AnyObject) {
        Animations.start(0.3){
            self.gradientMask.alpha = 0
        }
        self.pickerView.selectItemByOption(.Hide, animated: true)
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
            self.pickerView.selectItemByOption(.Hide, animated: true)
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
    
    // MARK: - CaptureButtonDelegate
    func didPressCaptureButton(sender: InitViewController){
        
        // only do ocr-mode if in verse detection
        if self.pickerView.selectedOption() == .VerseOCR {
            self.startOCRCaptureAction()
        }
        if self.pickerView.selectedOption() == .Hide {
            // scroll to end
            self.verseTable.scrollToEnd()
        }
    }
    
    func startOCRCaptureAction(){
        if self.captureLock.tryLock() {
            
          //  self.verseTable.isExpanded = false
           // self.verseTable.reloadData()
            
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
    
    
    func didReleaseCaptureButton(sender: InitViewController) -> Bool {
        
        if self.pickerView.selectedOption() == .Hide {
            return true // nothing to do
        }
        
        var hasNewMatches = false
        updateLock.lock()
        Timing.runAfter(0.3){
            self.captureBox.alpha = 0.0
        }

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
        if self.pickerView.selectedOption() == .Photo {
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
            self.pickerView.selectItemByOption(.Hide, animated: true)
        }
        
        if self.session.newMatches > 0 &&
            self.pickerView.selectedOption() == .VerseOCR {
            self.pickerView.selectItemByOption(.Hide, animated: false)
        }
        
        self.session.newMatches = 0
        self.session.active = false
        self.session.misses = 0
        
        // resort verse table by priority
        self.verseTable.sortByPriority()
        self.verseTable.reloadData()
        self.verseTable.scrollToEnd()

        
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
        return pickerView.optionDescription(item)
    }
    
    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        
        let option = pickerView.selectedOption()
        
        let hide = {
            switch option {
            case .Hide:
                // hide the kids
                self.photoImageView.alpha = 0.0
                self.captureAssetsAlpha(0.0)
                self.hideCaptureContainer(true)
                
                // open the shades
                self.hideGradients(true)
                
                // mannequin  
                self.cam.pause()
            case .Photo: // hide capture
                self.captureAssetsAlpha(0.0)
            case .VerseOCR: // hide photo
                self.photoImageView.alpha = 0.0

            }
        }
        let show = {
            switch option {
            case .Photo: // show photo
                self.hideCaptureContainer(false)
                self.photoImageView.alpha = 1.0
                self.resumeCam()
                
                // close the shades
                self.hideGradients(false)
            case .VerseOCR: // show capture
                self.hideCaptureContainer(false)
                self.captureImage.alpha = 1.0 // only showing image, box activated on press
                self.resumeCam()
                self.hideGradients(false)
                
            default: // nothing to show
                break
            }
        }
        
        // hide then show active item
        Animations.start(0.3, animations: hide)
        Animations.startAfter(0.3, forDuration: 0.3, animations: show)

    }
    
    func hideGradients(hidden: Bool){
       // self.scrollViewEscapeMask.hidden = hidden
        if hidden {
            self.gradientMask.alpha = 0
        } else {
            self.gradientMask.alpha = 1.0
        }
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
        
        if sender.direction == .Up || sender.direction == .Down {
            self.pickerView.selectItem(0, animated: true)
        }

        
    }
    
    // MARK - navigation
    @IBAction func showScriptPreview(sender: AnyObject) {
        self.navNext()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
}

enum PickerViewOption: Int { // as ordered in pickerview
    case Hide = 0, Photo, VerseOCR
    func description() -> String {
        switch self{
        case .Hide:
            return "SCRIPT"
        case .VerseOCR:
            return "VERSE DETECTION"
        case .Photo:
            return "PHOTO"
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
