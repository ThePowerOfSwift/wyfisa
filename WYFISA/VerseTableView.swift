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
    var hasHeader: Bool = true
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
        self.recentVerses[id-1].name = self.recentVerses[id-1].name+"."
    }
    
    func updateVerseAtIndex(id: Int, withVerseInfo verse: VerseInfo){
        self.recentVerses[id-1] = verse
    }
    
    // when a render fails the section id is 0
    // and the array value is the last one added
    func removeFailedVerse(){

        let idxSet = NSIndexSet(index: self.nVerses)
        self.nVerses = self.nVerses - 1

        Animations.start(0.2) {
            self.deleteSections(idxSet, withRowAnimation: .Top)
            self.recentVerses.removeAtIndex(self.recentVerses.count-1)
        }     
    }
    
    func addSection() {
        
        // add section after dummy section
        self.nVerses = self.nVerses + 1
        let idxSet = NSIndexSet(index: self.nVerses)

        self.insertSections(idxSet, withRowAnimation: .None)
        let path = NSIndexPath(forRow: 0, inSection: self.nVerses)
        
        // scroll down to new section to create a 'scroll up' effect
        self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
    }
    
    func scrollToEnd(){
        if self.nVerses > 0 {
            let path = NSIndexPath(forRow: 0, inSection: self.nVerses)
            self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // MARK: dataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 { // dummy row to padd table
            let dummyCell = VerseTableViewCell(style: .Default, reuseIdentifier: nil)
            dummyCell.hidden = true
            return dummyCell
        }
        
        var cell: VerseTableViewCell?
        
        cell = tableView.dequeueReusableCellWithIdentifier("verseCell") as! VerseTableViewCell?
        
        if cell == nil {
            let nib = UINib(nibName: "VerseTableViewCell", bundle: nil)
            tableView.registerNib(nib, forCellReuseIdentifier: "verseCell")
            cell = tableView.dequeueReusableCellWithIdentifier("verseCell") as! VerseTableViewCell?
        }
        
        if let verseCell = cell {
            verseCell.delegate = self.cellDelegate
            let index = indexPath.section - 1
            if self.recentVerses.count != 0 {
                verseCell.updateWithVerseInfo(self.recentVerses[index], isExpanded: self.isExpanded)
                return verseCell
            }
        }
        return VerseTableViewCell(style: .Default, reuseIdentifier: nil)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if indexPath.section == 0 {
            // padding row
            let headerHeight = tableView.frame.size.height - 60.0 * CGFloat(self.nVerses)
            if headerHeight <= 60 || self.isExpanded == true  || self.hasHeader == false{
                self.hasHeader = false
                return 0
            } else {
                return headerHeight
            }
        }
        if self.isExpanded == true {
            // dynamic text sizing
            let index = indexPath.section - 1
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
        return self.nVerses + 1
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let headerHeight = tableView.frame.size.height - 40.0 * CGFloat(self.nVerses)
        if headerHeight <= 60 {
            tableView.scrollEnabled = true
        } else {
            if self.isExpanded == false { // cannot freeze table in expanded view
                tableView.scrollEnabled = false
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
    func expandView(toSize: CGSize) -> Bool {
        self.reloadData()
        self.isExpanded = !self.isExpanded
        return self.isExpanded
    }
    
    func clear(){
        
        self.hasHeader = true
        
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

