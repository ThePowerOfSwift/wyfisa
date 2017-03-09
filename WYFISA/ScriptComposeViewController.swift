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
    @IBOutlet var noteTextInput: UITextField!
    @IBOutlet var notesBottomConstraint: NSLayoutConstraint!
    @IBOutlet var gradientMask: UIView!
    @IBOutlet var buttonStackView: UIStackView!
    @IBOutlet var notesButton: UIButton!
    @IBOutlet var captureContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var footerOverlay: UIView!
    @IBOutlet var captureViewOverlay: GPUImageView!
    var scrollViewEscapeMask: UIView!

    let themer = WYFISATheme.sharedInstance
    let cam = CameraManager.sharedInstance
    let settings = SettingsManager.sharedInstance
    var session = CaptureSession.sharedInstance
    let db = DBQuery.sharedInstance
    
    var scriptTitle: String? = nil
    var tableDataSource: VerseTableDataSource? = nil
    var isEditingMode: Bool = false
    var cameraEnabled: Bool = true
    var captureLock = NSLock()
    var updateLock = NSLock()
    var navNext = notifyCallback
    var kbo: KeyboardObserver? = nil
    var scriptID: String = randomString(10)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.themeView()

        // setup datasource
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size)
        self.tableDataSource?.cellDelegate = self
        self.verseTable.dataSource = self.tableDataSource
        self.verseTable.isExpanded = true
        self.verseTable.footerHeight = self.footerOverlay.frame.height
        self.verseTable.scrollNotifier = self.tableScrollNotifierFunc
        
        // setup picker view
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        self.pickerView.font = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedFont = UIFont.systemFontOfSize(14, weight: UIFontWeightBold)
        self.pickerView.highlightedTextColor = UIColor.offWhite(1.0)
        self.pickerView.textColor = UIColor.fire()
        self.pickerView.maskDisabled = false
        self.pickerView.reloadData()
        
        // misc delegates
        self.noteTextInput.delegate = self
        
        // photo preview
    
        self.captureImage.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addTarget(self.captureImage)
        
        // theme
        self.themeView()

    }
    
    override func viewDidAppear(animated: Bool) {
 
        
        self.updateSessionMatches()
        if let ds = self.tableDataSource {
            self.session.currentId = UInt64(ds.nVerses+1)
        }
        
        
        self.verseTable.reloadData()
        
        self.pickerView.selectItemByOption(.VerseOCR, animated: true)
        
        // keyboard
        self.initKeyboardObserver()
        
    }
    

    func tableScrollNotifierFunc(){
        /*
        if self.pickerView.selectedOption() != .Script {
            self.pickerView.selectItemByOption(.Script, animated: true)
        }
        */
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
          //  self.gradientMask.hidden = true
        }
        self.pickerView.selectItemByOption(.Photo, animated: true)
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
            //self.pickerView.selectItemByOption(.Script, animated: true)
        }
    }

    
    
    func exitEditingMode(){
        if self.verseTable.editing == true {
            self.verseTable.setEditing(false, animated: true)
        }
    }
    
    func themeView(){
        // bg color
        //self.view.backgroundColor = themer.whiteForLightOrNavy(1.0)
        self.view.backgroundColor = self.themer.offWhiteForLightOrNavy(0.70)

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
             //self.startOCRCaptureAction()
            var ok = 23;
        case .Photo:
            // add last image to list when in photo mode
            self.takePhoto()
        }
    }
    
    
    func addVersesToScript(verses: [VerseInfo]) {
        
        // carry verses over to editor table
        if let ds = self.tableDataSource {
            for verseInfo in verses {
                ds.appendVerse(verseInfo)
                dispatch_async(dispatch_get_main_queue()) {
                    self.verseTable.addSection()
                    self.verseTable.updateVersePriority(verseInfo.id, priority: verseInfo.priority)
                }
            }

        }
        self.verseTable.sortByPriority()
        self.verseTable.reloadData()
        self.verseTable.scrollToEnd()

    }
    
    func takePhoto(){
        
        let verseInfo = VerseInfo.init(id: "0", name: "", text: nil)
        verseInfo.session = self.session.updateCaptureId()
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
        
        self.pickerView.selectItemByOption(.VerseOCR, animated: true)
    }
    
    
    // MARK: - picker view
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        return 2
    }

    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        return pickerView.optionDescription(item)
    }
    
    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        
        let option = pickerView.selectedOption()
        self.cam.pause()

        func toggleViews(hidden: Bool) {
            Animations.start(0.3){
               // self.captureImage.hidden = hidden
               // self.captureViewOverlay.hidden = hidden
                self.hideActionButtons(!hidden)
                self.hideGradients(hidden)
                self.hideCaptureContainer(hidden)
                //self.view.layoutIfNeeded()
            }
        }
        
        switch option {
        case .Photo:
            self.resumeCam()
            toggleViews(false)
        case .VerseOCR:
            self.captureBox.alpha = 0
            toggleViews(true)
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
            verseInfo.session = self.session.updateCaptureId()
            
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
                verseInfo.session = self.session.updateCaptureId()
                
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
                verseInfo.session = self.session.updateCaptureId()
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
        

        switch segue.identifier ?? "" {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        case "VerseDetail":
            let toVc = segue.destinationViewController as! VerseDetailModalViewController
            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
        
        case "highlightsegue":
            // detect if this was a cell select
            let toVc = segue.destinationViewController as! InfoViewController
            if let verse = sender as? VerseInfo {
                toVc.isUpdate = true
                toVc.snaphot = verse.image
                toVc.verseInfo = verse
            }

        case "notesegue":
            // when editing a note then pass previous text to view
            if let verse = sender as? VerseInfo {
                let toVc = segue.destinationViewController as! NotesViewController
                if verse.session != 0 {
                    toVc.editingText = verse.name
                }
                toVc.verseInfo = verse
            }
        case "searchsegue":
            // give last verse from datasource
            if let ds = self.tableDataSource {
                if let verse = ds.getLastVerseItem() {
                    let toVc = segue.destinationViewController as! SearchViewController
                    toVc.verseInfo = verse
                }
            }
        default:
            break
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
        let verse = VerseInfo.init(id: "", name: "", text: nil)
        performSegueWithIdentifier("notesegue", sender: (verse as AnyObject))
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        //self.escapeMask.hidden = true
        let text = textField.text ?? ""
        
        if text != "" {
            
            let verseInfo = VerseInfo(id: "0", name:  text, text: nil)
            verseInfo.category = .Note
            
            // add verse to datasource
            verseInfo.session = self.session.updateCaptureId()
            
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
        kbo.yOffset = 0
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


