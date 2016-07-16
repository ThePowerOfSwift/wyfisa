//
//  VerseDetailModalViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VerseDetailModalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var segmentBar: UISegmentedControl!
    @IBOutlet var verseLabel: UILabel!
    @IBOutlet var chapterTextView: UITextView!
    @IBOutlet var referenceTable: UITableView!
    
    var verseInfo: VerseInfo? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let verse = verseInfo {
            self.chapterTextView.text = verse.chapter
            self.verseLabel.text = verse.name
        }
        self.referenceTable.dataSource = self
        self.referenceTable.delegate = self

    }
    
    override func viewDidAppear(animated: Bool) {
        self.chapterTextView.scrollRangeToVisible(NSMakeRange(0, 0))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapBarSegment(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // hide related
            Animations.start(0.2){
                self.referenceTable.alpha = 0
            }
            // show chapter
            Animations.startAfter(0.2, forDuration: 0.2){
                self.chapterTextView.alpha = 1
            }
        }
        
        if sender.selectedSegmentIndex == 1 {
            // hide chapter
            Animations.start(0.2){
                self.chapterTextView.alpha = 0
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var nsec = 0
        if let verse = self.verseInfo {
            if let refs = verse.refs {
                nsec = refs.count
            }
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
            if let refs = verseInfo!.refs {
                let refInfo = refs[indexPath.section]
                verseCell.updateWithVerseInfo(refInfo, isExpanded: true)
            }
            return verseCell
        } else {
            return VerseTableViewCell(style: .Default, reuseIdentifier: nil)
        }

    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // dynamic text sizing
        if let refs = verseInfo!.refs {
            if let text = refs[indexPath.section].text {
                let height = text.heightWithConstrainedWidth(self.referenceTable.frame.size.width,
                                                             font: UIFont.systemFontOfSize(16))
                
                if height  > 30  { // bigger than a loading text
                    return height + 50
                }
            }
        }
        return 60
    }
    
    // MARK: - navigation
    
    @IBAction func didPressCloseButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
