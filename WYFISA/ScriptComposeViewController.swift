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
                                VerseTableViewCellDelegate,
                                UITextFieldDelegate {

    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var noteTextInput: UITextField!
    @IBOutlet var notesBottomConstraint: NSLayoutConstraint!
    @IBOutlet var gradientMask: UIView!
    @IBOutlet var buttonStackView: UIStackView!
    @IBOutlet var notesButton: UIButton!
    
    @IBOutlet var footerFx: UIVisualEffectView!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var footerOverlay: UIView!
    @IBOutlet var captureViewOverlay: GPUImageView!
    var scrollViewEscapeMask: UIView!

    let themer = WYFISATheme.sharedInstance
    let settings = SettingsManager.sharedInstance
    var session = CaptureSession.sharedInstance
    let db = DBQuery.sharedInstance
    let storage = CBStorage.init(databaseName: SCRIPTS_DB, skipSetup: true)

    var scriptTitle: String? = nil
    var tableDataSource: VerseTableDataSource? = nil
    var isEditingMode: Bool = false
    var cameraEnabled: Bool = true
    var captureLock = NSLock()
    var updateLock = NSLock()
    var navNext = notifyCallback
    var kbo: KeyboardObserver? = nil
    var scriptId: String? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.themeView()

        // setup datasource
        self.tableDataSource = VerseTableDataSource.init(frameSize: self.view.frame.size, scriptId: scriptId!)
        self.tableDataSource?.cellDelegate = self
        self.verseTable.dataSource = self.tableDataSource
        self.verseTable.isExpanded = true
        self.verseTable.footerHeight = self.footerOverlay.frame.height
        self.verseTable.reloadData()
        self.session.currentId = self.tableDataSource!.getMaxSessionID()
        
        // flash
        self.configureFlashIcon()
        
        // misc delegates
        self.noteTextInput.delegate = self
        
        // theme
        self.themeView()

    }

    
    override func viewDidAppear(animated: Bool) {
 
        
        self.updateSessionMatches()
        
        // self.pickerView.selectItemByOption(.VerseOCR, animated: true)
        
        // keyboard
        self.initKeyboardObserver()
        
    }
    
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureFlashIcon(){
        
        if self.settings.useFlash == true {
            let buttonIcon = UIImage.init(named: "flash-fire")
            self.clearButton.setImage(buttonIcon, forState: .Normal)
        } else {
            let buttonIcon = UIImage.init(named: "flash")
            self.clearButton.setImage(buttonIcon, forState: .Normal)
        }
    }
    
    @IBAction func didPressClearButton(sender: UIButton) {
        
        // toggle editing mode
        self.settings.useFlash = !self.settings.useFlash
        self.configureFlashIcon()
        
    }

    
    
    func exitEditingMode(){
        if self.verseTable.isDeleteMode == true {
            self.verseTable.isDeleteMode = false
            self.verseTable.reloadData()
        }
    }
    
    func themeView(){
        // bg color
        self.view.backgroundColor = self.themer.offWhiteForLightOrNavy(0.70)
        self.footerOverlay.backgroundColor = self.themer.clearForLightOrNavy(1.0)
        if !self.themer.isLight() {
            self.footerFx.hidden = true
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
    
    
    // MARK: - CaptureButtonDelegate
    
    
    func addVersesToScript(verses: [VerseInfo]) {
        
        // carry verses over to editor table
        for verseInfo in verses {
            
            // add verse to db
            self.addVerseToDatastore(verseInfo, updateSession: false)
            
        }
        
        // update session for all verses
        CaptureSession.sharedInstance.updateCaptureId()

    }
    
    
    func addVerseToDatastore(verse: VerseInfo, updateSession: Bool = true){
        

        if verse.name == String.workingText {
            return // reject scanning cell's
        }

        // add verse to datasource
        verse.scriptId = self.scriptId
        verse.session = self.session.currentId
        self.tableDataSource?.appendVerse(verse)
        self.verseTable?.sortByPriority()
        
        // add the section to capture table and then reload
        Timing.runAfter(0.2){
            self.verseTable?.addSection()
        }
        
        // update script count
        storage.incrementScriptCountAndTimestamp(self.scriptId!)
        
        // create a new session
        if updateSession == true {
            CaptureSession.sharedInstance.updateCaptureId()
        }
        
    }

    // MARK: - navigation
    @IBAction func showScriptPreview(sender: AnyObject) {
        self.navNext()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return HIDE_STATUS_BAR
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return self.themer.statusBarStyle()
    }
    
    @IBAction func unwindFromReader(segue: UIStoryboardSegue) {
        //
    }
    
    @IBAction func unwindFromSearchAndQuit(segue: UIStoryboardSegue) {
        //
    }
    
    
    @IBAction func unwindFromSearchAndSave(segue: UIStoryboardSegue) {
        // add verse to datasource
        let searchVC = segue.sourceViewController as! SearchViewController
        
        
        if let verseInfo = searchVC.verseInfo {
            
            // add verse to datasource
            self.addVerseToDatastore(verseInfo)
            
            //self.captureVC?.session.newMatches += 1
            self.session.matches.append(verseInfo.id)
            
            // cache
            Timing.runAfterBg(0.3){
                self.db.chapterForVerse(verseInfo.id)
                self.db.crossReferencesForVerse(verseInfo.id)
                self.db.versesForChapter(verseInfo.id)
            }
            
            // note can become title
            if self.scriptTitle == nil || self.scriptTitle == "" {
                if let text = verseInfo.text {
                    self.setScriptTitleFromContext(text)
                }
            }

        }
    }
    
    
    
    func setScriptTitleFromContext(text: String){
        var i = 0
        var title:String = ""
        for word in (text.componentsSeparatedByString(" ")) {
            title.appendContentsOf("\(word) ")
            if i > 2 { break }
            i += 1
        }
        self.scriptTitle = title
        self.storage.updateScriptTitle(self.scriptId!, title: title)
        (self.parentViewController as! InitViewController).scriptTitle.text = title
    }
    
    
    @IBAction func unwindFromNotes(segue: UIStoryboardSegue) {
        
        let vc = segue.sourceViewController as! NotesViewController
        
        if let verseInfo = vc.verseInfo {
            
            if vc.isUpdate == false {
                self.addVerseToDatastore(verseInfo)
            } else {
                // updating data at this session
                self.tableDataSource?.updateRecentVerse(verseInfo)
                self.storage.updateScriptTimestamp(self.scriptId!)
            }
            self.verseTable.reloadData()
            
            // note can become title
            if self.scriptTitle == nil || self.scriptTitle == "" {
                self.setScriptTitleFromContext(verseInfo.name)
            }
        }
    }
    
    @IBAction func unwindFromNotesAndQuit(segue: UIStoryboardSegue) {
        //
    }
    
    
    @IBAction func unwindFromHighlight(segue: UIStoryboardSegue) {
        let vc = segue.sourceViewController as! InfoViewController
        
        if let verseInfo = vc.verseInfo {
            // updating the photo verse
            self.tableDataSource?.updateRecentVerse(verseInfo)
            self.verseTable.reloadData()
            self.storage.updateScriptTimestamp(self.scriptId!)
            if vc.didModifyOverlay {
                // save new overlay
                self.storage.updateVerseImage(verseInfo)
            }
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

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return true
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

    func didRemoveCell(sender: VerseTableViewCell) {
        // just removed one cell
        let verse = sender.verseInfo!
        self.verseTable.deleteVerse(verse)
        
        
        self.storage.decrementScriptCountAndTimestamp(self.scriptId!)
        self.syncWithDataSource()
    }
    
    func didTapInfoButtonForVerse(verse: VerseInfo) {
        // implement prototype
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
            self.addVerseToDatastore(verseInfo)
            
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
    }
    
    func closeNotesInput(){
        self.noteTextInput.text = nil
        self.noteTextInput.endEditing(true)
    }
}


