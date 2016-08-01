//
//  VerseDetailModalViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VerseDetailModalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, VerseTableViewCellDelegate {

    @IBOutlet var segmentBar: UISegmentedControl!
    @IBOutlet var verseLabel: UILabel!
    @IBOutlet var chapterTextView: UITextView!
    @IBOutlet var referenceTable: UITableView!
    @IBOutlet var versesTable: UITableView!
    @IBOutlet var splitButton: UIButton!

    var verseInfo: VerseInfo? = nil
    var startViewPos: Int = 0
    var splitMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        
        // Do any additional setup after loading the view.
        if let verse = verseInfo {
            self.verseLabel.text = verse.name
            
            if verse.chapter == nil { return } // nothing can be done
            
            // find context start position
            var chapter = verse.chapter!
            let startIdx = chapter.indexOfCharacter("\u{293}")
            let endIdx = chapter.indexOfCharacter("\u{297}")
            if startIdx == nil || endIdx == nil { return } // no context verse
            
            startViewPos = startIdx!
            chapter = chapter.strip("\u{293}")
            chapter = chapter.strip("\u{297}")

            let length = endIdx! - startIdx! - 1
            
            // contextual highlighting for attributed text
            let font = BodyFont.iowan(19.0)
            
            let attrs = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                         NSFontAttributeName: font]
            let attributedText = NSMutableAttributedString.init(string: chapter, attributes: attrs)
            var contextRange = NSRange.init(location: startIdx!, length: length)
            let contextAttrs = [NSForegroundColorAttributeName: UIColor.turquoise(),
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
    }
    
    // scroll to middle of screen when view appears
    override func viewDidAppear(animated: Bool) {
        var yPos = self.startViewPos
        yPos += Int(self.view.frame.height/2)
        Animations.start(0.3){
            self.chapterTextView.scrollRangeToVisible(NSMakeRange(yPos, 0))
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
    
    @IBAction func didPressSplitButton(sender: UIButton) {
        // toggles between showing chapter or split view of verses
        self.splitMode = !self.splitMode
        

        // call to reload table so that cells can be populated
        // with verse data
        if self.splitMode == true {
            
            self.splitButton.setImage(UIImage(named: "navicon-fire"), forState: .Normal)
            
            self.versesTable.reloadData()
            // scroll to verse
            if let activeVerse = self.verseInfo?.verse {
                let path = NSIndexPath.init(forRow: 0, inSection: activeVerse)
                self.versesTable.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
            }
        } else {
            self.splitButton.setImage(UIImage(named: "navicon"), forState: .Normal)
        }
        
        // hide unlreated views
        self.fadeOutInChapterVerseStack()
    }
    
    
    @IBAction func didTapBarSegment(sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            self.fadeOutInChapterVerseStack()
        }
        
        if sender.selectedSegmentIndex == 1 {
            self.referenceTable.reloadData()

            // hide chapter and verses
            Animations.start(0.2){
                self.chapterTextView.alpha = 0
                self.versesTable.alpha = 0
            }
            
            // show related
            Animations.startAfter(0.2, forDuration: 0.2){
                self.referenceTable.alpha = 1
            }
        }
        
    }
    override func prefersStatusBarHidden() -> Bool {
        return true
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
        if self.segmentBar.selectedSegmentIndex == 1 {
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
                let refInfo = refs[indexPath.section]
                verseCell.updateWithVerseInfo(refInfo, isExpanded: true)
                if let activeVerse = self.verseInfo?.verse {
                    if activeVerse == indexPath.section+1 {
                        verseCell.highlightText()
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
                let font = BodyFont.iowan(18.0)

                let height = text.heightWithConstrainedWidth(self.referenceTable.frame.size.width,
                                                             font: font)+10
                
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
    
    
    @IBAction func didPressCloseButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
