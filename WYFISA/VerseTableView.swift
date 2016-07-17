//
//  VerseTableView.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VerseTableView: UITableView, UITableViewDelegate, UITableViewDataSource {

    var nVerses: Int = 0
    var nVersesOffset: Int = 0
    var recentVerses: [VerseInfo] = [VerseInfo]()
    var isExpanded: Bool = false
    var nLock: NSLock = NSLock()
    var cellDelegate: VerseTableViewCellDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // setup tableview
        self.delegate = self
        self.dataSource = self
    }
    
    func setCellDelegate(delegate: VerseTableViewCellDelegate){
        self.cellDelegate = delegate
    }
    
    func addToSectionBy(i: Int){
        self.nVerses = self.nVerses + i
    }
    func appendVerse(verse: VerseInfo){
        self.recentVerses.append(verse)
    }
    
    func updateVersePending(id: Int){
        self.recentVerses[id].name = self.recentVerses[id].name+"."
    }
    
    func updateVerseAtIndex(id: Int, withVerseInfo verse: VerseInfo){
        self.recentVerses[id] = verse
    }
    
    // when a render fails the section id is 0
    // and the array value is the last one added
    func removeFailedVerse(){
        self.nVerses = self.nVerses - 1
        let idxSet = NSIndexSet(index: 0)
        Animations.start(0.2) {
            self.deleteSections(idxSet, withRowAnimation: .Top)
            self.recentVerses.removeAtIndex(self.recentVerses.count-1)
        }     
    }
    
    func addSection() {
        self.nVerses = self.nVerses + 1
        let idxSet = NSIndexSet(index: 0)
        self.insertSections(idxSet, withRowAnimation: .Fade)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // MARK: dataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        var cell: VerseTableViewCell?
        
        cell = tableView.dequeueReusableCellWithIdentifier("verseCell") as! VerseTableViewCell?
        
        if cell == nil {
            let nib = UINib(nibName: "VerseTableViewCell", bundle: nil)
            tableView.registerNib(nib, forCellReuseIdentifier: "verseCell")
            cell = tableView.dequeueReusableCellWithIdentifier("verseCell") as! VerseTableViewCell?
        }
        
        if let verseCell = cell {
            verseCell.delegate = self.cellDelegate
            let index = self.numberOfSectionsInTableView(tableView) - indexPath.section - 1
            verseCell.updateWithVerseInfo(self.recentVerses[index], isExpanded: self.isExpanded)
            return verseCell
        } else {
            return VerseTableViewCell(style: .Default, reuseIdentifier: nil)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if self.isExpanded == true {
            // dynamic text sizing
            let index = self.numberOfSectionsInTableView(tableView) - indexPath.section - 1
            if let text = self.recentVerses[index].text {
                let height = text.heightWithConstrainedWidth(self.frame.size.width*0.90,
                                                             font: UIFont.systemFontOfSize(16))
                if height  > 30 { // bigger than a loading text
                    return height + 50
                }
            }
        }
        return 60
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.nVerses
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
    func expandView(toSize: CGSize) -> Bool {
        
        Animations.start(0.2) {
            if self.isExpanded == false {
                self.frame.size.width = toSize.width*0.95
                self.frame.size.height = toSize.height*0.75
            } else {
                self.frame.size.width = toSize.width*0.40
                self.frame.size.height = toSize.height*0.35
            }
        }
        

        self.reloadData()
        self.isExpanded = !self.isExpanded
        return self.isExpanded
    }
    
    func clear(){
        
        // fade out table
        Animations.start(0.5) {
            self.alpha = 0
        }
        
        // clear table rows
        Timing.runAfter(1) {
            self.nVerses = 0
            self.recentVerses = [VerseInfo]()
            self.reloadData()
            self.alpha = 1
        }
    }

}

