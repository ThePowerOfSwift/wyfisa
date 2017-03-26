//
//  VerseDetailModalViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import Social

class VerseDetailModalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, VerseTableViewCellDelegate, FBStorageDelegate {

    @IBOutlet var segmentBar: UISegmentedControl!
    @IBOutlet var verseLabel: UILabel!
    @IBOutlet var chapterTextView: UITextView!
    @IBOutlet var referenceTable: UITableView!
    @IBOutlet var versesTable: UITableView!
    @IBOutlet var footerMask: UIImageView!
    @IBOutlet var closeButton: UIButton!
    @IBOutlet var navStackView: UIStackView!
    @IBOutlet var navBackgroundView: UIView!
    @IBOutlet var nextChapterButton: UIButton!
    @IBOutlet var prevChapterButton: UIButton!
    @IBOutlet var loadSpinner: UIActivityIndicatorView!
    
    var themer = WYFISATheme.sharedInstance
    var db = DBQuery.sharedInstance
    let firDB = FBStorage()
    var verseInfo: VerseInfo? = nil
    var startViewPos: Int = 0
    var splitMode: Bool = false
    var lastScrollPos: CGFloat = 0
    var footerIsHidden: Bool = false
    var didShowSplitVerseOnce: Bool = false
    var navIsHidden: Bool = false
    var nextVerse: VerseInfo? = nil
    var prevVerse: VerseInfo? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.firDB.delegate = self
        
        if let verse = verseInfo {
            if (verse.bookNo != nil) && (verse.chapterNo != nil){
                self.fetchCurrentChapter()
                self.fetchCurrentCrossRefs()
            }
        }
        
        self.segmentBar.selectedSegmentIndex = 1
        
        // apply color schema
        self.applyColorSchema()
    }
    
    func initView() {

        // show hide next/prev buttons
        self.setupNextPrevButtons()
        
        // Do any additional setup after loading the view.
        if let verse = verseInfo {
            
            if verse.chapter == nil { return } // nothing can be done
            
            // find context start position
            var chapter = verse.chapter!
            chapter = "\n\n\n\n\(chapter)\n\n"

            let startIdx = chapter.indexOfCharacter("\u{293}")
            let endIdx = chapter.indexOfCharacter("\u{297}")
            if startIdx == nil || endIdx == nil { return } // no context verse
            
            startViewPos = startIdx!
            chapter = chapter.strip("\u{293}")
            chapter = chapter.strip("\u{297}")
            let length = endIdx! - startIdx! - 1
            
            // contextual highlighting for attributed text
            let font = themer.currentFontAdjustedBy(1)
            
            let fontColor = themer.navyForLightOrWhite(1.0)
            let attrs = [NSForegroundColorAttributeName: fontColor,
                         NSFontAttributeName: font]
            let attributedText = NSMutableAttributedString.init(string: chapter, attributes: attrs)
            var contextRange = NSRange.init(location: startIdx!, length: length)
            let contextAttrs = [NSForegroundColorAttributeName: self.themer.fireForLightOrTurquoise(),
                                NSFontAttributeName: font]
            if (contextRange.location + contextRange.length) > attributedText.length {
                // some kind of overshoot occured - do not exceed bounds
                contextRange.location = attributedText.length - contextRange.length
            }
            attributedText.setAttributes(contextAttrs, range: contextRange)
            self.chapterTextView.attributedText = attributedText
        }
        self.referenceTable.dataSource = self
        self.referenceTable.delegate = self
        
        self.versesTable.dataSource = self
        self.versesTable.delegate = self
        
        self.chapterTextView.delegate = self
        

    }
    
    // scroll to middle of screen when view appears
    override func viewDidAppear(animated: Bool) {
        var yPos = self.startViewPos
        yPos += Int(self.view.frame.height/2)
        Animations.start(0.3){
            self.chapterTextView.scrollRangeToVisible(NSMakeRange(yPos, 0))
        }
        
        if self.segmentBar.selectedSegmentIndex == 1 {
            Timing.runAfter(0.5){
                self.showFooterMask()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setChapterVerseHideAlpha(){
        // hide reference table
        self.referenceTable.alpha = 0
        if self.splitMode == true {
            // hide chapter box
            self.chapterTextView.alpha = 0
        } else {
            self.versesTable.alpha = 0
        }
    }
    
    func setChapterVerseShowAlpha(){
        // hide reference table
        self.referenceTable.alpha = 0
        if self.splitMode == true {
            self.versesTable.alpha = 1
        } else {
            self.chapterTextView.alpha = 1
        }
    }
    
    func fadeOutInChapterVerseStack(){
        Animations.start(0.2, animations: self.setChapterVerseHideAlpha)
        
        // show related
        Animations.startAfter(0.2,
                              forDuration: 0.2,
                              animations: self.setChapterVerseShowAlpha)
    }
    
    @IBAction func didTapBarSegment(sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            self.splitMode = true
            // go to highligted verse on first time triggered
            if self.didShowSplitVerseOnce == false{
                
                // scroll to verse
                if let activeVerse = self.verseInfo?.verse {
                    let path = NSIndexPath.init(forRow: 0, inSection: activeVerse-1)
                    self.versesTable.scrollToRowAtIndexPath(path, atScrollPosition: .Middle, animated: false)
                    Timing.runAfter(0.5){
                        self.showFooterMask()
                    }
                    self.didShowSplitVerseOnce = true
                }
            }
            
            // hide unlreated views
            self.fadeOutInChapterVerseStack()
        } else {
            self.splitMode = false
        }
        
        if sender.selectedSegmentIndex == 1 {
            self.fadeOutInChapterVerseStack()
            self.showFooterMask()
        }
        
        if sender.selectedSegmentIndex == 2 {
            self.referenceTable.reloadData()
            
            // hide chapter and verses
            Animations.start(0.2){
                self.chapterTextView.alpha = 0
                self.versesTable.alpha = 0
            }
           // self.hideFooterMask()
            
            // show related
            Animations.startAfter(0.2, forDuration: 0.2){
                self.referenceTable.alpha = 1
            }
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return HIDE_STATUS_BAR
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return self.themer.statusBarStyle()
    }
    
    override func viewDidLayoutSubviews() {
        self.chapterTextView.setContentOffset(CGPointZero, animated: false)
    }
    
    // MARK: - tableview
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func versesForCell() -> [VerseInfo]? {
        
        // can either be verses or cross references
        if self.segmentBar.selectedSegmentIndex == 2 {
            return self.verseInfo?.refs
        }
        return  self.verseInfo?.verses
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var nsec = 0
        if let refs = self.versesForCell() {
            nsec = refs.count
        }
        return nsec
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        var footerHeight:CGFloat = 10.0
        return 10.0
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: VerseTableViewCell?
        
        cell = tableView.dequeueReusableCellWithIdentifier("verseCell") as! VerseTableViewCell?
        
        if cell == nil {
            let nib = UINib(nibName: "VerseTableViewCell", bundle: nil)
            tableView.registerNib(nib, forCellReuseIdentifier: "verseCell")
            cell = tableView.dequeueReusableCellWithIdentifier("verseCell") as! VerseTableViewCell?
        }
        
        if let verseCell = cell {
            if let refs = self.versesForCell() {
                if refs.count > indexPath.section {
                    let refInfo = refs[indexPath.section]
                    verseCell.updateWithVerseInfo(refInfo, isExpanded: true)
                    if let activeVerse = self.verseInfo?.verse {
                        if activeVerse == indexPath.section+1 {
                            verseCell.highlightText()
                        }
                    }
                }
            }
            verseCell.delegate = self
            return verseCell
        } else {
            return VerseTableViewCell(style: .Default, reuseIdentifier: nil)
        }

    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // dynamic text sizing
        if let refs = self.versesForCell() {
            if let text = refs[indexPath.section].text {
                let font = themer.currentFont()

                let height = text.heightWithConstrainedWidth(self.referenceTable.frame.size.width*0.90,
                                                             font: font)+font.pointSize
                
                if height  > 30  { // bigger than a loading text
                    return height + 50
                }
            }
        }
        return 65
    }
    
    
    // MARK: - navigation
    // MARK: - Table cell delegate
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo){
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let destVC = storyboard.instantiateViewControllerWithIdentifier("DetailView")
            as! VerseDetailModalViewController
        destVC.verseInfo = verse
        presentViewController(destVC, animated: true, completion: nil)

    }
    
    func didTapInfoButtonForVerse(verse: VerseInfo){
        //
    }
    
    func didRemoveCell(sender: VerseTableViewCell){
        //
    }
        
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        // save current possition of scrolling view
        lastScrollPos = scrollView.contentOffset.y
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if self.footerMaskEnabled() == false {
            return
        }
        
        let segmentPos = self.segmentBar.center.y
        if scrollView.contentOffset.y <= segmentPos {
            self.showFooterMask()
            self.showNavArea()
        } else if lastScrollPos < scrollView.contentOffset.y {
            if self.footerIsHidden == false {
                self.hideFooterMask()
            }
        }
    }
    
    
    @IBAction func didTapChapterText(sender: AnyObject) {
        self.showFooterMask()
        self.showNavArea()
    }
    
    func hideFooterMask(){
        
        
        if self.segmentBar.selectedSegmentIndex != 1 {
            return // must be in chapter mode
        }
        
        Animations.start(0.2){
            self.footerMask.alpha = 0
            self.closeButton.alpha = 0
            if self.nextVerse != nil {
                self.nextChapterButton.alpha = 0
            }
            if self.prevVerse != nil {
                self.prevChapterButton.alpha = 0
            }
        }
        self.footerIsHidden = true
        
        if self.navIsHidden == false && self.segmentBar.selectedSegmentIndex == 1 {
            self.hideNavArea()
        }
 
        
    }
    
    func showFooterMask(){
        Animations.start(0.2){
            self.footerMask.alpha = 0.90
            self.closeButton.alpha = 1
            if self.nextVerse != nil {
                self.nextChapterButton.alpha = 1
            }
            if self.prevVerse != nil {
                self.prevChapterButton.alpha = 1
            }
        }
        self.footerIsHidden = false
        if self.navIsHidden == true {
            self.showNavArea()
        }
    }
    
    func toggleFooterMask(){
        if self.footerIsHidden == true {
            self.showFooterMask()
        } else {
            self.hideFooterMask()
        }
    }
    
    func showNavArea(){
        self.navIsHidden = false
        Animations.start(0.5){
            self.navStackView.alpha = 1.0
            self.segmentBar.alpha = 1.0
            self.navBackgroundView.alpha = 1.0
        }
    }
    
    func hideNavArea(){
        self.navIsHidden = true
        Animations.start(0.5){
            self.navStackView.alpha = 0.0
            self.segmentBar.alpha = 0.0
            self.navBackgroundView.alpha = 0.0
        }
    }
    func toggleNavArea(){
        if self.navIsHidden == true {
            self.showNavArea()
        } else {
            self.hideNavArea()
        }
    }
    
    
    func footerMaskEnabled() -> Bool {
        return self.segmentBar.selectedSegmentIndex == 1
    }
    
    @IBAction func didPressCloseButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func didPressNextChapterButton(sender: AnyObject) {
        self.verseInfo = self.nextVerse
        self.fetchCurrentChapter()

    }
    
    @IBAction func didPressPrevChapterButton(sender: AnyObject) {
        self.verseInfo = self.prevVerse
        self.fetchCurrentChapter()
    }
    
    func fetchCurrentCrossRefs(){
        // get cross refs
        let refRanges = db.crossReferencesForVerse(self.verseInfo!.id)
        for range in refRanges {
            print("range", range.from, range.to)
            self.firDB.getVerseRange(range.from, range.to)
        }
    }
    
    func fetchCurrentChapter(){
        self.loadSpinner.startAnimating()

        let bookNo = self.verseInfo!.bookNo!
        let chapterNo = self.verseInfo!.chapterNo!
        let cacheKey = "\(bookNo)\(chapterNo)"
        self.verseLabel.text = self.verseInfo!.name

        if let verses = CHAPTER_CACHE[cacheKey] {
            self.didGetVerseContext(self, verses: verses, type: FBContextType.Chapter.rawValue)
        } else {
            self.firDB.getVerseContext(bookNo,
                                       chapterNo:  chapterNo)
        }
    }
    func handleChapterChange(){
        
        // reset state
        self.nextVerse = nil
        self.prevVerse = nil
        
        // redraw views
        self.initView()
        self.versesTable.reloadData()
        
        // scroll up to top
        self.chapterTextView.scrollRectToVisible(CGRect.init(x: 0, y: 0, width: 100, height: 10), animated: false)
        let path = NSIndexPath.init(forRow: 0, inSection: 0)
        self.versesTable.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
     
        Timing.runAfter(0.5){
            self.showNavArea()
            self.showFooterMask()
        }
    }
    func setupNextPrevButtons(){
        self.nextChapterButton.hidden = true
        self.prevChapterButton.hidden = true

        /* DEPRECIATED
        var bookNo = -1
        var chapterNo = -1
        
        if let b = self.verseInfo?.bookNo {
            bookNo = b
        }
        if let c = self.verseInfo?.chapterNo {
            chapterNo = c
        }
        if bookNo == -1 || chapterNo == -1 {
            return
        }
        
        if let nextVerse = db.nextChapter(bookNo, chapterId: chapterNo){
            // has next chapter
            self.nextVerse = nextVerse
            self.nextChapterButton.alpha = 1.0
        } else {
            self.prevChapterButton.alpha = 0.0
        }
        
        if let prevVerse = db.prevChapter(bookNo, chapterId: chapterNo){
            // has next chapter
            self.prevVerse = prevVerse
            self.prevChapterButton.alpha = 1.0
        } else {
            self.prevChapterButton.alpha = 0.0
        }
        */
        
    }
    func applyColorSchema(){
        let contentBackground = themer.whiteForLightOrNavy(1.0)
        self.view.backgroundColor = contentBackground
        self.chapterTextView.backgroundColor = contentBackground
        self.verseLabel.textColor = themer.navyForLightOrWhite(1.0)
        self.navBackgroundView.backgroundColor = themer.whiteForLightOrNavy(1.0)
        if themer.isLight() {
            self.footerMask.image = UIImage(named: "footer-mask-white")
        } else {
            self.footerMask.image = UIImage(named: "footer-mask")
        }
        
    }
    
    // MARK: - FIR Delegate
    func didGetVerseContext(sender: AnyObject, verses: [AnyObject], type: AnyObject){
        let rangeType = FBContextType(rawValue: type as! Int)!
        
        switch rangeType {
        case .Chapter:
            self.verseInfo?.updateChapterForVerses(verses as! [VerseInfo])
            self.handleChapterChange()
            self.loadSpinner.stopAnimating()
        case .Range:
            self.verseInfo?.updateRefsForVerses(verses as! [VerseInfo])
        }
    }
}
