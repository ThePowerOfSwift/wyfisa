//
//  VerseTableView.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VerseTableView: UITableView, UITableViewDelegate {


    var isExpanded: Bool = false
    var nLock: NSLock = NSLock()
    var cellDelegate: VerseTableViewCellDelegate?
    var themer = WYFISATheme.sharedInstance

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // setup tableview
        self.delegate = self
    }
    

    func getDatasource() -> VerseTableDataSource? {
        if let ds = self.dataSource {
            return ds as? VerseTableDataSource
        }
        return nil
    }
    

    func updateVerseAtIndex(id: Int, withVerseInfo verse: VerseInfo){
        if(id==0){
            return
        }
        let section = id-1
        let idxSet = NSIndexSet(index: section)
    
        if let ds = self.getDatasource() {
            ds.recentVerses[section-1] = verse
            ds.updateCellHeightVal(verse)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
             let path = NSIndexPath(forRow: 0, inSection: section)
             self.reloadSections(idxSet, withRowAnimation: .None)
             self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    // when a render fails the section id is 0
    // and the array value is the last one added
    func removeFailedVerse(){

        let idxSet = NSIndexSet(index: self.numberOfSections-1)

        Animations.start(0.2) {
            if let ds = self.getDatasource(){
                ds.nVerses = ds.nVerses - 1
                ds.recentVerses.removeAtIndex(ds.recentVerses.count-1)
            }
            self.deleteSections(idxSet, withRowAnimation: .Top)

        }
    }
    
    func addSection() {
        
        var nSections = self.numberOfSections
        // add section after dummy section
        if let ds = self.getDatasource(){
            ds.nVerses += 1
            nSections = ds.nVerses
        }
        
        let idxSet = NSIndexSet(index: nSections)

        self.insertSections(idxSet, withRowAnimation: .None)
        let path = NSIndexPath(forRow: 0, inSection: nSections)
        
        self.reloadSections(idxSet, withRowAnimation: .None)

        // scroll down to new section to create a 'scroll up' effect
        self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)

    }
    
    func scrollToEnd(){
        if self.numberOfSections > 2 {
            let path = NSIndexPath(forRow: 0, inSection: self.numberOfSections-1)
            self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    func sortByPriority(){
        if let ds = self.getDatasource() {
            ds.recentVerses.sortInPlace {
                if ($0.session != $1.session){
                    return $0.session < $1.session
                }
                return $0.priority > $1.priority
            }
        }
    }
    
    func updateVersePriority(id: String, priority: Float){
        var i = 0
        if let ds = self.getDatasource() {
            for var v in ds.recentVerses {
                if v.id == id {
                    ds.recentVerses[i].priority = priority
                }
                i+=1
            }
        }
    }
    

    

    
    func expandView(toSize: CGSize) -> Bool {
        self.reloadData()
        self.isExpanded = !self.isExpanded
        return self.isExpanded
    }
    
    func setContentToExpandedEnd() {
        if self.numberOfSections > 0 {
            var yOffset = self.contentSize.height - self.frame.size.height
            if yOffset < 0 {
                yOffset = 0
            }
            self.setContentOffset(CGPointMake(0, yOffset), animated: false)

        }
    }
    
    func setContentToCollapsedEnd() {
        let yOffset: CGFloat = CGFloat(self.numberOfSections)*65.0
        self.setContentOffset(CGPointMake(0, yOffset), animated: false)
    }
    
    func clear(){
        
        
        // fade out table
        Animations.start(0.3) {
            self.alpha = 0
        }
        
        if let ds = self.getDatasource(){
            ds.nVerses = 0
            ds.recentVerses = [VerseInfo]()
            ds.expandedCellHeights = 0.0
            ds.hasHeader = true
        }
        
        // clear table rows
        Timing.runAfter(0.5) {
            self.reloadData()
            self.alpha = 1
        }
    }
    
    

    func currentMatches() -> [String]{
        var matches = [String]()
        if let ds = self.getDatasource(){
            for m in ds.recentVerses {
                matches.append(m.id)
            }
        }
        return matches
    }
    
    // MARK: delegate methods
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
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
        
        // default height of collapsed cell
        var sectionHeight:CGFloat = 65
        
        if indexPath.section == 0 {
            
            // height of header section
            sectionHeight = 0
            
        }  else if self.isExpanded == true {
            
            // is expanded, so base height on size of text
            let index = indexPath.section - 1
            if let ds = self.getDatasource() {
                if let text = ds.recentVerses[index].text {
                    sectionHeight = ds.cellHeightForText(text, width: self.frame.size.width)
                }
            }
        }
        
        return sectionHeight
    }
    
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            
            // delete cell from datasource
            let idxSet = NSIndexSet(index: indexPath.section)
            if let ds = self.getDatasource() {
                ds.nVerses -= 1
                ds.recentVerses.removeAtIndex(indexPath.section-1)
            }
            
            // notify cell delegate of removed content
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! VerseTableViewCell
            cell.delegate?.didRemoveCell(cell)
            
            // drop celll from section
            tableView.deleteSections(idxSet, withRowAnimation: .Automatic)
            tableView.reloadData()
            
        }
    }
    
    

}

