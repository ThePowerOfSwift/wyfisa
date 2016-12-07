//
//  ScrollViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/17/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class ScrollViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate, VerseTableViewCellDelegate {

    @IBOutlet var scrollView: UIScrollView!
    var scriptVC: ScriptViewController? = nil
    var pauseVC: HistoryViewController? = nil
    var commonDataSource: VerseTableDataSource? = nil
    var activePage: Int = 0
    var onPageChange: (Int) -> () = defaultCallback

    var didLoad: Bool = false
    var tabBarHeight: CGFloat? = nil
    
    var bgCam: CameraManager = CameraManager.sharedInstance
    let db = DBQuery.sharedInstance
    var kbo: KeyboardObserver? = nil
    
    @IBOutlet var noteTextInput: UITextField!
    @IBOutlet var escapeMask: UIView!
    @IBOutlet var buttonStack: UIStackView!
    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var notesBottomConstraint: NSLayoutConstraint!
    @IBOutlet var backgroundTextFieldButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        let w = self.view.frame.size.width
        self.scrollView.contentSize.width = 2*w
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        self.scriptVC = storyboard.instantiateViewControllerWithIdentifier("scriptvc") as? ScriptViewController
        self.pauseVC = storyboard.instantiateViewControllerWithIdentifier("historyvc") as? HistoryViewController

        self.pauseVC?.view.frame.origin.x = 0
        self.scriptVC?.view.frame.origin.x = w

        
        // set data sources
        let ds = VerseTableDataSource(frameSize: self.view.frame.size)
        ds.cellDelegate = self
        self.scriptVC?.configure(self.view.frame.size)
        self.commonDataSource = ds

        // setup navigation
        self.scriptVC?.navPrev = self.scrollToEdit
        self.pauseVC?.navNext = self.scrollToScript
        self.pauseVC?.scrollViewEscapeMask = self.escapeMask
        
        // add controllers to scroll view
        //self.scrollView.addSubview(pauseVC!.view)
        //self.scrollView.addSubview(scriptVC!.view)
        
    }


    override func viewDidAppear(animated: Bool) {
        if (!self.didLoad) {
            self.didLoad = true
            
            self.scrollView.contentOffset.x = 0
            
            // init keyboard observers
            self.noteTextInput.delegate = self
            initKeyboardObserver()
        }
        
        // theme it
        self.scrollView.backgroundColor = WYFISATheme.sharedInstance.whiteForLightOrNavy(1.0)

    }
    
    func scrollToPage(_ page: Int){
        Animations.start(0.3){
            self.scrollView.contentOffset.x = self.view.frame.size.width*CGFloat(page)
        }
    }


    func resumeCamIfActive(){
        if self.pauseVC?.pickerView.selectedItem != 0 {
            self.pauseVC?.resumeCam()
        }
    }
    
    func pauseCamIfActive(){
        if self.pauseVC?.pickerView.selectedItem != 0 {
            self.pauseVC?.resumeCam()
        }
    }

    
    // MARK: - Navigation

    func scrollToScript(){
        // pause camera
        self.pauseCamIfActive()
        
        // reload script
        self.scriptVC?.refresh()
        
        // scroll over
        self.scrollToPage(1)
        self.activePage = 1
        
        // end all editing
        self.pauseVC?.exitEditingMode()
        
        // hide actions
        self.buttonStack.hidden = true
        self.backgroundTextFieldButton.hidden = true

    }
    
    func scrollToEdit(){
        self.resumeCamIfActive()
        self.activePage = 0
        self.buttonStack.hidden = false
        self.backgroundTextFieldButton.hidden = false
        self.scrollToPage(0)

    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        // make sure we're not deleting cells
        self.pauseVC?.exitEditingMode()


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
            if let ds = self.commonDataSource {
                if let verse = ds.getLastVerseItem() {
                    let toVc = segue.destinationViewController as! SearchViewController
                    toVc.verseInfo = verse
                }
            }
        }
    }
    
    @IBAction func didPressClearButton(sender: AnyObject) {
        self.pauseVC?.didPressClearButton(sender)
    }

    
    // MARK: - cell delegate
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo){
        if sender.editing == false { // don't segue if cell is being edited
            switch verse.category {
            case .Verse:
                performSegueWithIdentifier("VerseDetail", sender: (verse as! AnyObject))
            case .Note:
                performSegueWithIdentifier("notesegue", sender: (verse as! AnyObject))
            case .Image:
                performSegueWithIdentifier("highlightsegue", sender: (verse as! AnyObject))
            }
        }
    }
    
    func didTapInfoButtonForVerse(verse: VerseInfo){
        performSegueWithIdentifier("infosegue", sender: (verse as! AnyObject))
    }
    
    func didRemoveCell(sender: VerseTableViewCell) {
        // just removed one cell
        self.pauseVC?.syncWithDataSource()
        self.pauseVC?.exitEditingMode()
        
    }
    
    @IBAction func unwindFromHighlight(segue: UIStoryboardSegue) {
        let vc = segue.sourceViewController as! InfoViewController
        
        if let verseInfo = vc.verseInfo {
            self.scrollToPage(0)

            if vc.isUpdate == false {
                // add verse to datasource
                verseInfo.session = (self.pauseVC?.updateCaptureId())!
                self.commonDataSource?.appendVerse(verseInfo)
                
                // add the section to capture table and then reload pauseVC
                dispatch_async(dispatch_get_main_queue()) {
                    if let table = self.pauseVC?.verseTable {
                        table.addSection()
                    }
                }
            } else {
                // updating data at this session
                self.commonDataSource?.updateRecentVerse(verseInfo)
            }
            self.pauseVC?.verseTable.reloadData()
            self.pauseVC?.verseTable.scrollToEnd()
        }
        
        // resume cam if we quit
        if self.activePage == 1 {
            self.bgCam.resume()
        }
    }
    
    @IBAction func unwindFromNotes(segue: UIStoryboardSegue) {
        
        let vc = segue.sourceViewController as! NotesViewController
        
        if let verseInfo = vc.verseInfo {
            self.scrollToPage(0)

            if vc.isUpdate == false {
                // add verse to datasource
                verseInfo.session = (self.pauseVC?.updateCaptureId())!
                
                self.commonDataSource?.appendVerse(verseInfo)
                
                // add the section to capture table and then reload pauseVC
                dispatch_async(dispatch_get_main_queue()) {
                    if let table = self.pauseVC?.verseTable {
                        table.addSection()
                    }
                }
            } else {
                // updating data at this session
                self.commonDataSource?.updateRecentVerse(verseInfo)
            }
            self.pauseVC?.verseTable.reloadData()
            self.pauseVC?.verseTable.scrollToEnd()
        }
    }
    
    @IBAction func unwindFromNotesAndQuit(segue: UIStoryboardSegue) {
        //
    }

    
    @IBAction func unwindFromSearchAndQuit(segue: UIStoryboardSegue) {
        //
    }
    @IBAction func unwindFromSearchAndSave(segue: UIStoryboardSegue) {
        // add verse to datasource
        let searchVC = segue.sourceViewController as! SearchViewController
        

        if let verseInfo = searchVC.verseInfo {
            
            self.scrollToPage(0)
            
            // add verse to datasource
            verseInfo.session = (self.pauseVC?.updateCaptureId())!

             self.commonDataSource?.appendVerse(verseInfo)
            
             // add the section to capture table and then reload pauseVC
             dispatch_async(dispatch_get_main_queue()) {
                if let table = self.pauseVC?.verseTable {
                     table.addSection()
                }
             }
            
             //self.captureVC?.session.newMatches += 1
             self.pauseVC?.session.matches.append(verseInfo.id)
             
             // cache
             Timing.runAfterBg(0.3){
                 self.db.chapterForVerse(verseInfo.id)
                 self.db.crossReferencesForVerse(verseInfo.id)
                 self.db.versesForChapter(verseInfo.id)
             }
            
            self.pauseVC?.verseTable.reloadData()
            self.pauseVC?.verseTable.scrollToEnd()
        }
    }

    
    // MARK - keyboard watcher
    @IBAction func didPressNotesButton(sender: UIButton) {
        if self.activePage == 1 {
            self.bgCam.pause()
        }
        self.noteTextInput.text = nil
        self.noteTextInput.hidden = false
        self.noteTextInput.becomeFirstResponder()
        
        self.escapeMask.hidden = false
        
        // make sure exit editing mode when creating a note
        self.pauseVC?.exitEditingMode()
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.escapeMask.hidden = true
        let text = textField.text ?? ""
    
        if text != "" {

            let verseInfo = VerseInfo(id: "0", name:  text, text: nil)
            verseInfo.category = .Note
            
            // add verse to datasource
            verseInfo.session = (self.pauseVC?.updateCaptureId())!
            
            self.commonDataSource?.appendVerse(verseInfo)
            
            // add the section to capture table and then reload pauseVC
            dispatch_async(dispatch_get_main_queue()) {
                if let table = self.pauseVC?.verseTable {
                    table.addSection()
                }
            }
            
            self.scrollToPage(0)
        } else {
            // did nothing
            if self.activePage == 1 {
                self.bgCam.resume()
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
        kbo.yOffset = self.tabBarHeight ?? 0
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
        self.pauseVC?.didTapGradientMask(sender)
    }
    func closeNotesInput(){
        self.noteTextInput.text = nil
        self.noteTextInput.endEditing(true)
    }

}
