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
class ViewController: UIViewController, CameraManagerDelegate, VerseTableViewCellDelegate, UIScrollViewDelegate, UISearchBarDelegate {

    @IBOutlet var debugWindow: GPUImageView!
    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var maskView: UIView!
    @IBOutlet var captureBox: UIImageView!
    @IBOutlet var refeshButton: UIButton!
    @IBOutlet var capTut: UILabel!
    @IBOutlet var tutScrollView: UIScrollView!
    @IBOutlet var tutPager: UIPageControl!
    @IBOutlet var tutImage: UIImageView!
    
    @IBOutlet var trashIcon: UIButton!
    @IBOutlet var escapeMask: UIView!
    @IBOutlet var searchView: UIView!
    @IBOutlet var searchBar: UISearchBar!
    let stillCamera = CameraManager.sharedInstance
    let db = DBQuery.sharedInstance
    let themer = WYFISATheme.sharedInstance
    let settings = SettingsManager.sharedInstance
    var session = CaptureSession()
    var captureLock = NSLock()
    var updateLock = NSLock()
    var workingText = "Scanning"
    var settingsEnabled: Bool = false
    var nightEnabled: Bool = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.firstLaunchTut()
        
        verseTable.setCellDelegate(self)

        // send camera to live view
        self.checkCameraAccess()
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        self.stillCamera.addCameraTarget(self.filterView)
        // self.stillCamera.addDebugTarget(self.debugWindow)
        
        // camera config
        stillCamera.zoom(1)
        stillCamera.focus(.ContinuousAutoFocus)
        
        // start capture
        stillCamera.capture()
        stillCamera.delegate = self
        stillCamera.pause()
        
        // warmup
        Timing.runAfterBg(0.5){
            self.stillCamera.recognizeFrameFromCamera(100)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.verseTable.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Capture
    @IBAction func didPressCaptureButton(sender: AnyObject) {
        
        self.hideTut()
        
        // make sure not in editing mode
        self.exitEditingMode()
        
        if self.captureLock.tryLock() {
            
            // show capture box
            self.captureBox.hidden = false

            self.verseTable.isExpanded = false
            self.verseTable.reloadData()
            self.verseTable.setContentToCollapsedEnd()

            Animations.start(0.3) {
               // self.captureBox.alpha = 0
                self.maskView.alpha = 0
            }
            
            // camera init
            stillCamera.resume()
            if self.settings.useFlash == true {
                stillCamera.torch(.On)
            }

            // session init
            self.session.active = true
            let sessionId = self.session.currentId
            session.clearCache()

            // adds row to verse table
            let defaultVerse = VerseInfo(id: "", name: self.workingText, text: "")
            self.verseTable.appendVerse(defaultVerse)
            self.verseTable.addSection()
            
            Timing.runAfter(0.2){
                self.verseTable.scrollToEnd()
            }
            
            // capture frames
            let asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(asyncQueue) {
                while self.session.currentId == sessionId {
                    self.stillCamera.recognizeFrameFromCamera(sessionId)
                }
            }
            self.captureLock.unlock()
        }
        
    }

    func handleCaptureEnd(){
        
        updateLock.lock()
        stillCamera.pause()
        if self.settings.useFlash == true {
            stillCamera.torch(.Off)
        }
        
        // remove scanning box
        if self.session.newMatches == 0 && self.session.active {
            self.verseTable.removeFailedVerse()
        }
        
        // hide capture box
        self.verseTable.isExpanded = true
        Animations.start(0.3) {
            self.captureBox.hidden = true
           // self.captureBox.alpha = 0
            self.maskView.alpha = 0.6
        }
        
        self.session.currentId += 1
        self.session.newMatches = 0
        self.session.active = false
        self.session.misses = 0
        
        // resort verse table by priority
        self.verseTable.sortByPriority()
        self.verseTable.reloadData()
        self.verseTable.setContentToExpandedEnd()

        updateLock.unlock()

    }
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject) {
        self.handleCaptureEnd()
    }
    @IBAction func didReleaseCaptureButtonOutside(sender: AnyObject) {
        self.handleCaptureEnd()
    }
    
    // MARK: - Process
    
    // when frame has been processed we need to write it back to the cell
    func didProcessFrame(sender: CameraManager, withText text: String, fromSession: UInt64) {
        //print(text)
        if fromSession != self.session.currentId {
            return // Ignore: from old capture session
        }
        
        updateLock.lock()

        let id = self.verseTable.nVerses+1
        if let allVerses = TextMatcher().findVersesInText(text) {

            for var verseInfo in allVerses {
                
                if let verse = self.db.lookupVerse(verseInfo.id){

                    // we have match
                    verseInfo.text = verse
                    verseInfo.session = fromSession

                    self.verseTable.updateVersePriority(verseInfo.id, priority: verseInfo.priority)
                    
                    // make sure not repeat match
                    if self.session.matches.indexOf(verseInfo.id) == nil {
                        
                        // first match replaces scanning icon
                        if self.session.newMatches == 0 {
                            self.verseTable.updateVerseAtIndex(id-1, withVerseInfo: verseInfo)
                        } else {
                            // new match
                            self.verseTable.appendVerse(verseInfo)
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
        
        performSegueWithIdentifier("VerseDetail", sender: (verse as! AnyObject))
    }

     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

         // pause camera
        dispatch_async(dispatch_get_main_queue()) {
            self.stillCamera.pause()
        }
        
         // Get the new view controller using segue.destinationViewController.
         // Pass the selected object to the new view controller.
        if segue.identifier == "VerseDetail" {
            let toVc = segue.destinationViewController as! VerseDetailModalViewController

            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
        }
        
        if segue.identifier == "searchsegue" {
            let toVc = segue.destinationViewController as! SearchBarViewController
            toVc.escapeMask = self.escapeMask
            toVc.searchView = self.searchView
            self.searchBar.delegate = toVc
        }
        
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

            
                // new match
                self.verseTable.appendVerse(verseInfo)
                dispatch_async(dispatch_get_main_queue()) {
                    self.verseTable.addSection()
                }
                self.session.newMatches += 1
                self.session.matches.append(verseInfo.id)
        }
    
        // end session
        self.handleCaptureEnd()

        
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
    

    func firstLaunchTut(){
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.stringForKey("isAppAlreadyLaunchedOnce") == nil {
            showTut()
            // only set to bool when they've seen forecast page
            defaults.setBool(true, forKey: "isAppAlreadyLaunchedOnce")
        }
        
        self.capTut.hidden = false
        Animations.startAfter(1, forDuration: 0.5){
            self.capTut.alpha = 1
        }
    }

    @IBAction func didSwipeTut(sender: AnyObject) {
    }
    
    func showTut(){
        /*
        self.tutScrollView.hidden = false
        self.tutPager.hidden = false
        self.tutScrollView.contentSize.width = self.view.frame.size.width * 4.0
        self.tutScrollView.delegate = self
        self.captureButton.hidden = true
        self.captureBox.hidden = true
        self.refeshButton.hidden = true
        */
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page =  self.tutScrollView.contentOffset.x/self.view.frame.size.width
        self.tutPager.currentPage = Int(page)
        switch page {
        case 0:
                self.tutImage.alpha = 0
            Animations.start(0.2){
                self.tutImage.alpha = 1
                self.tutImage.image = UIImage.init(named: "Find")
            }

        case 1:
                self.tutImage.alpha = 0
            Animations.start(0.2){
                self.tutImage.alpha = 1
                self.tutImage.image = UIImage.init(named: "Capture")
            }
        case 2:
            self.tutImage.alpha = 0
            Animations.start(0.2){
                self.tutImage.alpha = 1
                self.tutImage.image = UIImage.init(named: "Study")
            }
        default:
            // done
            self.tutScrollView.delegate = self
            self.captureButton.hidden = false
            self.captureBox.hidden = false
            self.refeshButton.hidden = false
            Animations.start(0.1){
                self.tutScrollView.alpha = 0
                self.tutScrollView.hidden = true
                self.tutScrollView.delegate = nil
                self.tutPager.hidden = true
            }


        }
    }

    @IBAction func didTapView(sender: UITapGestureRecognizer) {
        // if we are showing search view
        // tell delegate that editing ended
        if let delegate = self.searchBar.delegate {
           delegate.searchBarTextDidEndEditing!(self.searchBar)
        }
    }
    
    func updateEditingView(){
        if self.verseTable.editing == true { // enter editing mode
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
        self.updateEditingView()
        if mode == false { // finished an edit
             self.session.matches = self.verseTable.currentMatches()
        }
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
            self.updateEditingView()
        }
    }
    
    func hideTut() {
        Animations.start(0.2){
            self.capTut.hidden = true
        }
    }

}


