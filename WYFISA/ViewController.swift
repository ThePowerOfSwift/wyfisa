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
class ViewController: UIViewController, VerseTableViewCellDelegate, UIScrollViewDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet var debugWindow: GPUImageView!
    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var maskView: UIView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var refeshButton: UIButton!
    @IBOutlet var captureBoxActive: UIImageView!
    
    @IBOutlet var capTut: UILabel!
    @IBOutlet var trashIcon: UIButton!
    @IBOutlet var escapeMask: UIView!
    @IBOutlet var searchView: UIView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var bottomNavBar: UITabBar!
    @IBOutlet var collectionItem: UITabBarItem!
    @IBOutlet var settingsItem: UITabBarItem!
    @IBOutlet var searchBarBG: UIView!
    
    let db = DBQuery.sharedInstance
    let themer = WYFISATheme.sharedInstance
    let settings = SettingsManager.sharedInstance
    var session = CaptureSession()
    var cam: CameraManager? = nil
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

        if self.firstLaunch == false {
            self.firstLaunch = true
            self.initCamera()
        }
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
        self.cam = CameraManager()
        
        if self.cam?.captureStarted == false {
            self.cam?.start()
        }
        
        // send camera to live view
        self.checkCameraAccess()
        self.filterView.fillMode = GPUImageFillModeType.init(2)

        // put a gaussian blur on the live view
        self.cam?.addCameraBlurTargets(self.filterView)
        
        // camera config
        self.cam?.zoom(1)
        self.cam?.focus(.ContinuousAutoFocus)

    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.verseTable.reloadData()
        
        if firstLaunch == true {
            self.capTut.hidden = false
        }
        if let size = self.frameSize {
            self.view.frame.size = size
        }
        
        if self.isExpanded == true {
            self.captureBox.hidden = true
            self.maskView.alpha = 0.6
            self.searchBar.hidden = false
            self.trashIcon.hidden = false
            self.searchBarBG.hidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func doCaptureAction(){
        if self.captureLock.tryLock() {

            self.cam?.resume()
            
            // show capture box
            self.captureBoxActive.hidden = false
            self.captureBox.hidden = false

            
            //self.verseTable.isExpanded = false
            self.verseTable.reloadData()
            self.verseTable.setContentToCollapsedEnd()
            
            Animations.start(0.3) {
                self.maskView.alpha = 0
            }
            
            // flash capture box
            Animations.fadeOutIn(0.3, tsFadeOut: 0.3, view: self.captureBox, alpha: 0)
            
            // camera init
            self.cam?.resume()
            
            if self.settings.useFlash == true {
                self.cam?.torch(.On)
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
                
                if let image = self.cam?.imageFromFrame(){
                    
                    // do image recognition
                    if let recognizedText = self.cam?.processImage(image){
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
            self.cam?.torch(.Off)
        }
        
        // remove scanning box
        if self.session.newMatches == 0 && self.session.active {
            self.verseTable.removeFailedVerse()
        } else {
            hasNewMatches = true
        }
        
        // hide capture box
        //self.verseTable.isExpanded = true
        self.captureBoxActive.hidden = true
//        self.captureBox.hidden = false

        
        self.session.currentId += 1
        self.session.newMatches = 0
        self.session.active = false
        self.session.misses = 0
        
        // resort verse table by priority
        self.verseTable.sortByPriority()
        self.verseTable.setContentToExpandedEnd()

        updateLock.unlock()
        return hasNewMatches
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
    
    // MARK: - Table cell delegate
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo){
        if sender.editing == false {
            performSegueWithIdentifier("VerseDetail", sender: (verse as! AnyObject))
        }
    }
    
    func didTapInfoButtonForVerse(verse: VerseInfo){
        performSegueWithIdentifier("infosegue", sender: (verse as! AnyObject))
    }
    
    func didRemoveCell(sender: VerseTableViewCell) {
        // update session matches to reflect new set of cells
        self.session.matches = self.verseTable.currentMatches()
        if self.session.matches.count == 0 {
            // removed all cells, exit editing mode
            self.exitEditingMode()
        }
    }

     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

         // pause camera
        dispatch_async(dispatch_get_main_queue()) {
 //           self.cam?.pause()
        }
        
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
        if segue.identifier == "VerseDetail" {
            let toVc = segue.destinationViewController as! VerseDetailModalViewController

            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
        }
        
        if segue.identifier == "infosegue" {
            let toVc = segue.destinationViewController as! InfoViewController
            
            // make a partial controller
            let width = self.view.frame.width
            toVc.preferredContentSize = CGSize(width:width, height: 460)
            let controller = toVc.popoverPresentationController
            controller?.delegate = self
            controller?.sourceView = self.captureBox
            controller?.sourceRect = CGRect(x:CGRectGetMidX(self.view.bounds),
                                            y: CGRectGetMidY(self.view.bounds)*0.70,
                                            width: width,
                                            height: 420)
            controller?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)

            self.escapeMask.alpha = 0
            self.escapeMask.hidden = false
            
            Animations.start(0.3){
                self.escapeMask.backgroundColor = UIColor.navy(1.0)
                self.escapeMask.alpha = 0.7
            }
            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
            toVc.doneCallback = self.hideEscapeMask
        }
        
        if segue.identifier == "searchsegue" {
            let toVc = segue.destinationViewController as! SearchBarViewController
            toVc.escapeMask = self.escapeMask
            toVc.searchView = self.searchView
            self.searchBar.delegate = toVc
            
        }

        // make sure tutorial is gone if we're pressing buttons!
        self.capTut.hidden = true
        
     }
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        
        if identifier == "settingsegue" {
            // if search bar is up, close it
            // this is not a true editing mode
            if self.escapeMask.hidden == false {
                if let delegate = self.searchBar.delegate {
                    delegate.searchBarTextDidEndEditing!(self.searchBar)
                }
                return false
            }
        }
        return true
    }

    func closeSearchView(){
        // clean up search results
        Animations.start(0.3){
            self.searchView.alpha = 0
            self.searchBar.text = nil
        }
        
        Timing.runAfter(0.3){
            self.searchBar.endEditing(true)
        }
        
    }
    
    @IBAction func unwindFromSearch(segue: UIStoryboardSegue) {
        
        self.closeSearchView()
        self.exitEditingMode()
        
        // add verse if matched
        let fromVC = segue.sourceViewController as! SearchBarViewController
        if let verseInfo = fromVC.resultInfo {
                verseInfo.session = self.session.currentId

            //    self.verseTable.reloadData()
            
                // new match
                self.tableDataSource?.appendVerse(verseInfo)
                dispatch_async(dispatch_get_main_queue()) {
                    self.verseTable.addSection()
                }
                self.session.newMatches += 1
                self.session.matches.append(verseInfo.id)
               //TODO: probabaly ust brok
                // self.verseTable.updateCellHeightVal(verseInfo)
        }
    
        // end session
        self.handleCaptureEnd()
        self.capTut.hidden = true
        
    }
    
    @IBAction func unwindFromSettings(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func unwindFromInfo(segue: UIStoryboardSegue) {
        self.escapeMask.backgroundColor = UIColor.clearColor()
        self.escapeMask.hidden = true
    }
    

    override func prefersStatusBarHidden() -> Bool {
        return false
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

    @IBAction func didTapView(sender: UITapGestureRecognizer) {
        // if we are showing search view
        // tell delegate that editing ended
        if let delegate = self.searchBar.delegate {
           delegate.searchBarTextDidEndEditing!(self.searchBar)
        }
        
    }
    
    func updateEditingView(toMode: Bool){
        if toMode == true { // enter editing mode
            Animations.start(0.5){
                self.refeshButton.alpha = 1
                self.trashIcon.setImage(UIImage(named: "ios7-trash-fire"), forState: .Normal)
            }
        } else {
            Animations.start(0.5){
                self.refeshButton.alpha = 0
                self.trashIcon.setImage(UIImage(named: "ios7-trash-outline"), forState: .Normal)
            }
        }
    }
    
    @IBAction func didTapTrashIcon(sender: AnyObject) {

        
        // if search bar is up, close it
        // this is not a true editing mode
        if self.escapeMask.hidden == false {
            if let delegate = self.searchBar.delegate {
                delegate.searchBarTextDidEndEditing!(self.searchBar)
            }
            return
        }

        let mode = !self.verseTable.editing
        self.verseTable.setEditing(mode, animated: true)
        self.updateEditingView(mode)
    }
    
    @IBAction func didTapClearAllButton(sender: UIButton) {
        self.exitEditingMode()
        if captureLock.tryLock(){
            self.session.currentId = 0
            
            // empty table
            self.verseTable.clear()
            
            // clear matches on session
            self.session.matches = [String]()
            
            // unlock safely after clear operation
            Timing.runAfter(1){
                self.captureLock.unlock()
            }
        }
        
    }
    
    func exitEditingMode(){
        if self.verseTable.editing == true {
            self.verseTable.setEditing(false, animated: true)
            self.updateEditingView(false)
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        self.hideEscapeMask()
    }
    
    func hideEscapeMask(){
        self.escapeMask.backgroundColor = UIColor.clearColor()
        self.escapeMask.hidden = true
    }

    // tab bar nav
    @IBAction func didPressCollectionButton(sender: AnyObject) {
        self.settingsItem.image = UIImage(named: "ios7-gear-outline")
//       self.collectionItem.image
    }
    
    @IBAction func didPressSettingsButton(sender: AnyObject) {
        self.settingsItem.image = UIImage(named: "ios7-gear-fire")
    }
    
}


