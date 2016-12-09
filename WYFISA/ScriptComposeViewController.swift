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

class ScriptComposeViewController: UIViewController,
                                CaptureButtonDelegate,
                                AKPickerViewDataSource,
                                AKPickerViewDelegate,
                                VerseTableViewCellDelegate,
                                UITextFieldDelegate {

    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var captureImage: GPUImageView!
    @IBOutlet var captureContainer: UIView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var captureBoxActive: UIImageView!
    @IBOutlet var pickerView: AKPickerView!
    @IBOutlet var photoImageView: GPUImageView!
    @IBOutlet var noteTextInput: UITextField!
    @IBOutlet var notesBottomConstraint: NSLayoutConstraint!
    @IBOutlet var gradientMask: UIView!
    @IBOutlet var buttonStackView: UIStackView!
    @IBOutlet var notesButton: UIButton!
    @IBOutlet var captureContainerHeightConstraint: NSLayoutConstraint!
    
    var captureDelegate: CaptureButtonDelegate? = nil
    var scrollViewEscapeMask: UIView!

    let themer = WYFISATheme.sharedInstance
    let cam = CameraManager.sharedInstance
    let settings = SettingsManager.sharedInstance
    let db = DBQuery.sharedInstance
    let sharedOutles = SharedOutlets.instance
    
    var tableDataSource: VerseTableDataSource? = nil
    var isEditingMode: Bool = false
    var cameraEnabled: Bool = true
    var workingText = "Scanning"
    var session = CaptureSession()
    var captureLock = NSLock()
    var updateLock = NSLock()
    var navNext = notifyCallback
    var kbo: KeyboardObserver? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.themeView()
        
        // setup camera
        self.captureImage.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addTarget(self.captureImage)
        self.initCamera()

        // setup datasource
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size)
        self.tableDataSource?.cellDelegate = self
        self.verseTable.dataSource = self.tableDataSource
        self.verseTable.isExpanded = true
        self.verseTable.scrollNotifier = self.tableScrollNotifierFunc
        
        // setup picker view
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.pickerView.font = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedFont = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedTextColor = UIColor.fire()
        self.pickerView.maskDisabled = false
        self.pickerView.reloadData()
        
        // misc delegates
        self.noteTextInput.delegate = self
        self.sharedOutles.captureDelegate = self
        
        // theme
        self.themeView()

    }
    
    override func viewDidAppear(animated: Bool) {
 
        
        self.updateSessionMatches()
        if let ds = self.tableDataSource {
            self.session.currentId = UInt64(ds.nVerses+1)
        }
        self.verseTable.reloadData()
        if self.tableDataSource?.nVerses > 0 {
            // hide picker and show current media
            // allows middle to operate as down button
            self.pickerView.selectItemByOption(.Script, animated: true)
        } else {
            // show the verse ocr
            self.pickerView.selectItemByOption(.Photo, animated: true)
        }
        
        // keyboard
        self.initKeyboardObserver()
    }
    

    func tableScrollNotifierFunc(){
        if self.pickerView.selectedOption() != .Script {
            self.pickerView.selectItemByOption(.Script, animated: true)
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


    @IBAction func hideGradientMask(sender: AnyObject) {
        Animations.start(0.3){
            self.gradientMask.hidden = true
        }
        self.pickerView.selectItemByOption(.Script, animated: true)
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
            self.pickerView.selectItemByOption(.Script, animated: true)
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
        
        let option = self.pickerView.selectedOption()
        
        switch option {
        case .VerseOCR:
            // only do ocr-mode if in verse detection
             self.startOCRCaptureAction()
        case .Script:
            // scroll to end
            self.verseTable.scrollToEnd()
        case .Photo:
            // add last image to list when in photo mode
            self.takePhoto()
        }
    }
    
    func takePhoto(){
        
        let verseInfo = VerseInfo.init(id: "0", name: "", text: nil)
        verseInfo.session = self.updateCaptureId()
        verseInfo.category = .Image
        let captureImage =  self.cam.imageFromFrame()
        verseInfo.image = captureImage
        verseInfo.accessoryImage = captureImage
        self.tableDataSource?.appendVerse(verseInfo)
        
        // add the section to capture table and then reload pauseVC
        dispatch_async(dispatch_get_main_queue()) {
            self.verseTable.addSection()
            self.verseTable.reloadData()
            self.verseTable.scrollToEnd()
        }

        self.pickerView.selectItemByOption(.Script, animated: true)
        
    }
    
    func startOCRCaptureAction(){
        if self.captureLock.tryLock() {
    
            
            // flash capture box
            Animations.fadeOutIn(0.3, tsFadeOut: 0.3, view: self.captureBox, alpha: 0)
            
            if self.settings.useFlash == true {
                self.cam.torch(.On)
            }
            
            // session init
            self.session.active = true
            session.clearCache()
            
            /*
            if self.verseTable.isExpanded == true {
                // compress table to view results
                Timing.runAfter(0.2){
                    self.verseTable.isExpanded = false
                    self.verseTable.reloadData()
                    self.verseTable.scrollToEnd()
                }
            }
            */
            
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
    
    
    func didReleaseCaptureButton(sender: InitViewController) -> Bool {
        
        if self.pickerView.selectedOption() != .VerseOCR {
            return true // nothing to do
        }
        
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
        self.updateCaptureId()

        if self.session.newMatches > 0 &&
            self.pickerView.selectedOption() == .VerseOCR {
            self.pickerView.selectItemByOption(.Script, animated: false)
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
        
        func toggleViews(hidden: Bool) {
            Animations.start(0.3){
                self.captureImage.hidden = hidden
                self.hideActionButtons(!hidden)
                self.hideGradients(hidden)
                self.hideCaptureContainer(hidden)
                self.view.layoutIfNeeded()
            }
        }
        
        switch option {
        case .Script:
            self.cam.pause()
            toggleViews(true)
            self.verseTable.reloadData()
        case .Photo:
            self.resumeCam()
            self.captureBox.alpha = 0
            self.captureContainerHeightConstraint.constant = 0
            toggleViews(false)
        case .VerseOCR:
            self.resumeCam()
            self.captureBox.alpha = 1
            self.captureContainerHeightConstraint.constant -= 100
            toggleViews(false)
        }
    }
    
    func hideGradients(hidden: Bool){
        self.gradientMask.hidden = hidden
       // self.scrollViewEscapeMask.hidden = hidden
    }
    
    func hideActionButtons(hidden: Bool){
        self.buttonStackView.hidden = hidden
        self.notesButton.hidden = hidden
    }

    func captureAssetsAlpha(alpha: CGFloat) {
       // self.captureImage.alpha = alpha
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

    // MARK: - navigation
    @IBAction func showScriptPreview(sender: AnyObject) {
        self.navNext()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    @IBAction func unwindFromSearchAndQuit(segue: UIStoryboardSegue) {
        //
    }
    
    @IBAction func unwindFromSearchAndSave(segue: UIStoryboardSegue) {
        // add verse to datasource
        let searchVC = segue.sourceViewController as! SearchViewController
        
        
        if let verseInfo = searchVC.verseInfo {
            
            // add verse to datasource
            verseInfo.session = self.updateCaptureId()
            
            self.tableDataSource?.appendVerse(verseInfo)
            
            // add the section to capture table and then reload pauseVC
            dispatch_async(dispatch_get_main_queue()) {
                if let table = self.verseTable {
                    table.addSection()
                }
            }
            
            //self.captureVC?.session.newMatches += 1
            self.session.matches.append(verseInfo.id)
            
            // cache
            Timing.runAfterBg(0.3){
                self.db.chapterForVerse(verseInfo.id)
                self.db.crossReferencesForVerse(verseInfo.id)
                self.db.versesForChapter(verseInfo.id)
            }
            
            self.verseTable.reloadData()
            self.verseTable.scrollToEnd()
        }
    }
    
    
    
    @IBAction func unwindFromNotes(segue: UIStoryboardSegue) {
        
        let vc = segue.sourceViewController as! NotesViewController
        
        if let verseInfo = vc.verseInfo {
            
            if vc.isUpdate == false {
                // add verse to datasource
                verseInfo.session = self.updateCaptureId()
                
                self.tableDataSource?.appendVerse(verseInfo)
                
                // add the section to capture table and then reload pauseVC
                dispatch_async(dispatch_get_main_queue()) {
                    if let table = self.verseTable {
                        table.addSection()
                    }
                }
            } else {
                // updating data at this session
                self.tableDataSource?.updateRecentVerse(verseInfo)
            }
            self.verseTable.reloadData()
        }
    }
    
    @IBAction func unwindFromNotesAndQuit(segue: UIStoryboardSegue) {
        //
    }
    
    
    @IBAction func unwindFromHighlight(segue: UIStoryboardSegue) {
        let vc = segue.sourceViewController as! InfoViewController
        
        if let verseInfo = vc.verseInfo {
            
            if vc.isUpdate == false {
                // add verse to datasource
                verseInfo.session = self.updateCaptureId()
                self.tableDataSource?.appendVerse(verseInfo)
                
                // add the section to capture table and then reload pauseVC
                dispatch_async(dispatch_get_main_queue()) {
                    if let table = self.verseTable {
                        table.addSection()
                    }
                }
            } else {
                // updating data at this session
                self.tableDataSource?.updateRecentVerse(verseInfo)
            }
            self.verseTable.reloadData()
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // make sure we're not deleting cells
        self.exitEditingMode()
        
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "VerseDetail" {
            let toVc = segue.destinationViewController as! VerseDetailModalViewController
            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
        }
        
        if segue.identifier == "highlightsegue" {
            let toVc = segue.destinationViewController as! InfoViewController
            // detect if this was a cell select
            if let verse = sender as? VerseInfo {
                toVc.isUpdate = true
                toVc.snaphot = verse.image
                toVc.verseInfo = verse
            }
        }
        if segue.identifier == "notesegue" {
            
            // when editing a note then pass previous text to view
            if let verse = sender as? VerseInfo {
                let toVc = segue.destinationViewController as! NotesViewController
                toVc.editingText = verse.name
                toVc.verseInfo = verse
            }
        }
        if segue.identifier == "searchsegue" {
            // give last verse from datasource
            if let ds = self.tableDataSource {
                if let verse = ds.getLastVerseItem() {
                    let toVc = segue.destinationViewController as! SearchViewController
                    toVc.verseInfo = verse
                }
            }
        }
    }

    
    // MARK: - versetablecell delegate
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo){
        if sender.editing == false { // don't segue if cell is being edited
            switch verse.category {
            case .Verse:
                performSegueWithIdentifier("VerseDetail", sender: (verse as AnyObject))
            case .Note:
                performSegueWithIdentifier("notesegue", sender: (verse as AnyObject))
            case .Image:
                performSegueWithIdentifier("highlightsegue", sender: (verse as AnyObject))
            }
        }
    }
    
    func didTapInfoButtonForVerse(verse: VerseInfo){
        // depreciated
    }
    
    func didRemoveCell(sender: VerseTableViewCell) {
        // just removed one cell
        self.syncWithDataSource()
        self.exitEditingMode()
        
    }
    
    // MARK: - notes handler
    @IBAction func didPressNotesButton(sender: UIButton) {
        if self.pickerView.selectedOption() != .Script {
            self.pickerView.selectItemByOption(.Script, animated: false)
        }
        
        self.noteTextInput.text = nil
        self.noteTextInput.hidden = false
        self.noteTextInput.becomeFirstResponder()
        
       // self.escapeMask.hidden = false
        
        // make sure exit editing mode when creating a note
        self.exitEditingMode()
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //self.escapeMask.hidden = true
        let text = textField.text ?? ""
        
        if text != "" {
            
            let verseInfo = VerseInfo(id: "0", name:  text, text: nil)
            verseInfo.category = .Note
            
            // add verse to datasource
            verseInfo.session = self.updateCaptureId()
            
            self.tableDataSource?.appendVerse(verseInfo)
            
            // add the section to capture table and then reload pauseVC
            dispatch_async(dispatch_get_main_queue()) {
                if let table = self.verseTable {
                    table.addSection()
                }
            }
            
        }
        
        
        self.noteTextInput.hidden = true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func initKeyboardObserver(){
        let kbo = KeyboardObserver(self, constraint: self.notesBottomConstraint)
        kbo.yOffset = self.sharedOutles.tabBarFrame?.height ?? 0
        kbo.frameOffset = 1
        self.kbo = kbo
    }
    func keyboardWillShow(notification:NSNotification) {
        self.kbo?.keyboardWillShow(notification)
    }
    func keyboardWillHide(notification:NSNotification) {
        self.kbo?.keyboardWillHide(notification)
    }
    
    @IBAction func didTapEscapeMask(sender: AnyObject) {
        self.closeNotesInput()
        self.hideGradientMask(sender)
    }
    
    func closeNotesInput(){
        self.noteTextInput.text = nil
        self.noteTextInput.endEditing(true)
    }

}

enum PickerViewOption: Int {
    // as ordered in pickerview
    case Script = 0, Photo, VerseOCR
    func description() -> String {
        switch self{
        case .Script:
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
