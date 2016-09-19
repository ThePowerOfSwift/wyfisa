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
    var expandedCellHeights: CGFloat = 0.0
    var recentVerses: [VerseInfo] = [VerseInfo]()
    var isExpanded: Bool = false
    var initHeaderHeight: CGFloat = 0
    var hasHeader: Bool = true
    var nLock: NSLock = NSLock()
    var cellDelegate: VerseTableViewCellDelegate?
    var themer = WYFISATheme.sharedInstance

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // setup tableview
        self.delegate = self
        self.dataSource = self
        self.initHeaderHeight = self.frame.size.height
    }
    
    func setCellDelegate(delegate: VerseTableViewCellDelegate){
        self.cellDelegate = delegate
    }
    
    func addToSectionBy(i: Int){
        self.nVerses = self.nVerses + i
    }
    
    func updateCellHeightVal(verse: VerseInfo){
        if let text = verse.text {
            let height = cellHeightForText(text)
            expandedCellHeights += height
        }
    }
    
    func appendVerse(verse: VerseInfo){
        self.recentVerses.append(verse)
        if(verse.id != ""){
            updateCellHeightVal(verse)
        }
    }
    
    func updateVersePending(id: Int){
        self.recentVerses[id-1].name = self.recentVerses[id-1].name+"."
    }
    
    func updateVerseAtIndex(id: Int, withVerseInfo verse: VerseInfo){
        if(id==0){
            return
        }
        self.recentVerses[id-1] = verse
        let idxSet = NSIndexSet(index: id)
        updateCellHeightVal(verse)
        
        dispatch_async(dispatch_get_main_queue()) {
             let path = NSIndexPath(forRow: 0, inSection: self.nVerses)
             self.reloadSections(idxSet, withRowAnimation: .None)
             self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
        }
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
        
        self.reloadSections(idxSet, withRowAnimation: .None)

        // scroll down to new section to create a 'scroll up' effect
        self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)

    }
    
    func scrollToEnd(){
        if self.nVerses > 0 {
            let path = NSIndexPath(forRow: 0, inSection: self.nVerses)
            self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func sortByPriority(){
        self.recentVerses.sortInPlace {
            if ($0.session != $1.session){
                return $0.session < $1.session
            }
            return $0.priority > $1.priority
        }
    }
    
    func updateVersePriority(id: String, priority: Float){
        var i = 0
        for var v in self.recentVerses {
            if v.id == id {
                self.recentVerses[i].priority = priority
            }
            i+=1
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
    
    // MARK: Header
    func heightForHeaderSection() -> CGFloat {
        var headerHeight = self.initHeaderHeight
        if self.isExpanded == true {
            if self.expandedCellHeights < self.frame.height {
                headerHeight = self.frame.height - self.expandedCellHeights
            } else {
                headerHeight = 0
            }
        }
        
        return headerHeight
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if self.isExpanded == false {
            // fade in new cells
            cell.alpha = 0
            Animations.start(0.3){
                cell.alpha = 1
            }
        }
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        var sectionHeight:CGFloat = 65.0 // default height of collapsed cell
        
        if indexPath.section == 0 {
            
            // height of header section
            sectionHeight = 0 // heightForHeaderSection()/2
            
        }  else if self.isExpanded == true {
            
            // is expanded, so base height on size of text
            let index = indexPath.section - 1
            if let text = self.recentVerses[index].text {
                sectionHeight = cellHeightForText(text)
            }
        }
        
        return sectionHeight
    }
    
    func cellHeightForText(text: String) -> CGFloat {
        let font = themer.currentFont()
        var height = text.heightWithConstrainedWidth(self.frame.size.width*0.90,
                                                     font: font)+10
        if height  > 30 { // bigger than a loading text
            height+=50
        }
        
        return height
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.nVerses + 1
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        

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
    
    func setContentToExpandedEnd() {
        if self.recentVerses.count > 0 {
            var yOffset = self.contentSize.height - self.frame.size.height
            if yOffset < 0 {
                yOffset = 0
            }
            self.setContentOffset(CGPointMake(0, yOffset), animated: false)

        }
    }
    
    func setContentToCollapsedEnd() {
        let yOffset: CGFloat = CGFloat(self.nVerses)*65.0
        self.setContentOffset(CGPointMake(0, yOffset), animated: false)
    }
    
    func clear(){
        
        self.hasHeader = true
        self.expandedCellHeights = 0.0
        
        // fade out table
        Animations.start(0.3) {
            self.alpha = 0
        }
        
        // clear table rows
        Timing.runAfter(0.5) {
            self.nVerses = 0
            self.recentVerses = [VerseInfo]()
            self.reloadData()
            self.alpha = 1
        }
    }
    
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {

            
            // delete cell from datasource
            let idxSet = NSIndexSet(index: indexPath.row)
            self.nVerses -= 1
            self.recentVerses.removeAtIndex(indexPath.row)
            
            // notify cell delegate of removed content
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! VerseTableViewCell
            cell.delegate?.didRemoveCell(cell)
            
            // drop celll from section
            tableView.deleteSections(idxSet, withRowAnimation: .Automatic)
            self.reloadData()
            
        }
    }
    
    func currentMatches() -> [String]{
        var matches = [String]()
        for m in self.recentVerses {
            matches.append(m.id)
        }
        return matches
    }

}

