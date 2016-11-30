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
    var captureVC: ViewController? = nil
    var pauseVC: HistoryViewController? = nil
    var commonDataSource: VerseTableDataSource? = nil
    var activePage: Int = 1
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
        self.scrollView.contentSize.width = w * 2.0
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        self.captureVC = storyboard.instantiateViewControllerWithIdentifier("capturevc") as? ViewController
        self.pauseVC = storyboard.instantiateViewControllerWithIdentifier("historyvc") as? HistoryViewController

        self.pauseVC?.view.frame.origin.x = 0
        self.captureVC?.view.frame.origin.x = w

        
        // set data sources
        let ds = VerseTableDataSource(frameSize: self.view.frame.size)
        ds.cellDelegate = self
        self.captureVC?.configure(ds, isExpanded: false, size: self.view.frame.size)
        self.pauseVC?.configure(ds, isExpanded: true, size: self.view.frame.size)
        self.commonDataSource = ds
        
        // add controllers to scroll view
        self.scrollView.addSubview(pauseVC!.view)
        self.scrollView.addSubview(captureVC!.view)

        // enable filter view
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        
        // put a gaussian blur on the live view
        self.bgCam.start()
        self.bgCam.addCameraBlurTargets(self.filterView)
        
        // setup callbacks from child view
        self.pauseVC?.notifyClearVerses = self.handleClearAllNotification
        
    }


    override func viewDidAppear(animated: Bool) {
        if (!self.didLoad) {
            self.didLoad = true
            
            // show history view... if we have history
            if self.commonDataSource?.nVerses > 0 {
                self.scrollView.contentOffset.x = 0
                self.scrollToPage(0)
            } else {
                // otherwise show capture
                self.scrollView.contentOffset.x =  self.view.frame.size.width
            }
            
            // init keyboard observers
            self.noteTextInput.delegate = self
            initKeyboardObserver()

        }
    }
    
    func scrollToPage(_ page: Int){
        
        if page == self.activePage {
            // already here
            self.onPageChange(page)
            return
        }
        
        self.activePage = page
        
        Animations.start(0.3){
            self.scrollView.contentOffset.x = self.view.frame.size.width*CGFloat(page)
            
            // moving to pause page
            if page == 0 {
                
                // make sure cam is paused
                self.captureVC?.cam.pause()
                // make sure view is up to date
                self.pauseVC?.verseTable.reloadData()

                // scroll to end
                self.pauseVC?.verseTable.scrollToEnd()
                
            } else  { // leaving pause page
                
                // resume cam on scroll to active page
                self.captureVC?.cam.resume()
                self.captureVC?.syncWithDataSource()
                self.captureVC?.verseTable.reloadData()
            }
        }
        
        self.onPageChange(page)

    }
    

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page =  self.scrollView.contentOffset.x/self.view.frame.size.width
        self.activePage = Int(page)

        if self.activePage == 0 {
            self.captureVC?.cam.pause()
        }
        
        self.onPageChange(self.activePage)
        

    }

    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        // make cam hot on moves, we can pause later
        self.captureVC?.cam.resume()
        
        // make sure exit editing mode when we are scrolling
        self.pauseVC?.exitEditingMode()

    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {

    }
    
    // MARK: - Navigation

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
        self.captureVC?.syncWithDataSource()
        self.pauseVC?.exitEditingMode()
        
    }
    
    @IBAction func unwindFromHighlight(segue: UIStoryboardSegue) {
        let vc = segue.sourceViewController as! InfoViewController
        
        if let verseInfo = vc.verseInfo {
            self.scrollToPage(0)

            if vc.isUpdate == false {
                // add verse to datasource
                verseInfo.session = (self.captureVC?.updateCaptureId())!
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
                verseInfo.session = (self.captureVC?.updateCaptureId())!
                
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
            verseInfo.session = (self.captureVC?.updateCaptureId())!

             self.commonDataSource?.appendVerse(verseInfo)
            
             // add the section to capture table and then reload pauseVC
             dispatch_async(dispatch_get_main_queue()) {
                if let table = self.pauseVC?.verseTable {
                     table.addSection()
                }
             }
            
             //self.captureVC?.session.newMatches += 1
             self.captureVC?.session.matches.append(verseInfo.id)
             
             // cache
             Timing.runAfterBg(0.3){
                 self.db.chapterForVerse(verseInfo.id)
                 self.db.crossReferencesForVerse(verseInfo.id)
                 self.db.versesForChapter(verseInfo.id)
             }
            
            self.pauseVC?.verseTable.reloadData()
        }
    }
    
    func handleClearAllNotification(){
        self.captureVC?.verseTable.reloadData()
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
            verseInfo.session = (self.captureVC?.updateCaptureId())!
            
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
    }
    func closeNotesInput(){
        self.noteTextInput.text = nil
        self.noteTextInput.endEditing(true)
    }

}
