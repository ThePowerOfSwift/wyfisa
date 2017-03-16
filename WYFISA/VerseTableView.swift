//
//  VerseTableView.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VerseTableView: UITableView, UITableViewDelegate, FBStorageDelegate {


    var isExpanded: Bool = false
    var nLock: NSLock = NSLock()
    var cellDelegate: VerseTableViewCellDelegate?
    var themer = WYFISATheme.sharedInstance
    var scrollNotifier: ()->() =  notifyCallback
    var footerHeight: CGFloat? = nil
    let firDB = FBStorage()
    let storage = CBStorage.init(databaseName: SCRIPTS_DB, skipSetup: true)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // setup tableview
        self.delegate = self
        self.firDB.delegate = self

    }
    

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        
        if self.editing == true {
            return UITableViewCellEditingStyle.Delete
        }
        return UITableViewCellEditingStyle.None
    }

    func getDatasource() -> VerseTableDataSource? {
        if let ds = self.dataSource {
            return ds as? VerseTableDataSource
        }
        return nil
    }
    

    func updateVerseAtIndex(id: Int, withVerseInfo verse: VerseInfo){
        if(id<=1){
            return
        }
        let section = id-1
        let idxSet = NSIndexSet(index: section)
    
        if let ds = self.getDatasource() {
            ds.recentVerses[section-1] = verse
            ds.updateCellHeightVal(verse)
            if ds.ephemeral == false {
                ds.storage.putVerse(verse)
            }
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

        if nLock.tryLock() {
            var nSections = self.numberOfSections
            // add section after dummy section
            if let ds = self.getDatasource(){

                ds.nVerses += 1
                nSections = ds.nVerses
            }
            
            // get verse text
            self.fetchVerseText(nSections-1)
            
            let idxSet = NSIndexSet(index: nSections)
            self.insertSections(idxSet, withRowAnimation: .None)
            let path = NSIndexPath(forRow: 0, inSection: nSections)
            
            self.reloadSections(idxSet, withRowAnimation: .None)

            // scroll down to new section to create a 'scroll up' effect
            self.scrollToRowAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
            
            nLock.unlock()
        }

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
        
        nLock.lock()
        
        // fade out table
        Animations.start(0.3) {
            self.alpha = 0
        }
        
        if let ds = self.getDatasource(){
            // remove from db
            if ds.ephemeral == false {
                for v in ds.recentVerses {
                    ds.storage.removeVerse(v.createdAt)
                }
            }
            
            // remove from ds
            ds.nVerses = 0
            ds.recentVerses = [VerseInfo]()
            ds.expandedCellHeights = 0.0
            ds.hasHeader = true
        }
        
        // reload
        self.reloadData()
        
        // fade in
        Animations.start(0.5) {
            self.alpha = 1
        }
        nLock.unlock()
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
        var footerHeight:CGFloat = 10.0
        
        // use a larger footer when rendering last section in table
        if section == (self.numberOfSections - 1){
            if let height = self.footerHeight {
                footerHeight = height
            }
        }
    
        return footerHeight
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
    
    func fetchVerseText(section: Int){
        var verseToFetch:VerseInfo? = nil
        
        if let ds = self.getDatasource() {
            if ds.recentVerses.count > section {
                let verse = ds.recentVerses[section]
                if (verse.category == .Verse && verse.id != "") {
                    if (verse.version != SettingsManager.sharedInstance.version.text()){
                        // version missmatch
                        verseToFetch = verse
                    } else if let vtext = verse.text {
                        if vtext == "" {
                            verseToFetch = verse
                        }
                    }
                }
            }
        }
        
        if verseToFetch != nil {
            firDB.getVerseDoc(verseToFetch!.id, section: section)
        }
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if self.isExpanded == false {
            // fade in new cells
            cell.alpha = 0
            Animations.start(0.3){
                cell.alpha = 1
            }
        }
        
        // update version if necessary
        self.fetchVerseText(indexPath.section)
        
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
                let verse = ds.recentVerses[index]
                switch  verse.category {
                case .Verse:
                    if let text = verse.text {
                        sectionHeight = ds.cellHeightForText(text, width: self.frame.size.width * 0.95)
                    }
                case .Note:
                     sectionHeight = ds.cellHeightForText(verse.name, width: self.frame.size.width*0.80)
                case .Image:
                    sectionHeight += 200
                }
            }
        } else { // non expanded
            
            // only show verses in quick view
            let index = indexPath.section - 1
            if let ds = self.getDatasource() {
                if ds.recentVerses.count == 0 {
                    sectionHeight = 0  // nothing here
                } else {
                    let verse = ds.recentVerses[index]
                    if verse.category != .Verse {
                        sectionHeight = 0
                    }
                }
            }
        }
        
        return sectionHeight
    }
    
    // MARK - scroll
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.scrollNotifier()
    }
    
    override func pressesBegan(presses: Set<UIPress>, withEvent event: UIPressesEvent?) {
        super.pressesBegan(presses, withEvent: event)
        self.scrollNotifier()
    }
    
    
    // MARK: - FIR Delegate
    func didGetSingleVerseForRow(sender: AnyObject, verse: AnyObject, section: Int){
        
        if let ds = self.getDatasource() {
            if ds.recentVerses.count > section {
                let dsVerse = ds.recentVerses[section]
                let fbVerse = verse as! VerseInfo
                dsVerse.text = fbVerse.text
                self.storage.updateVerse(dsVerse)
                self.reloadData()
            }
        }
    }
    
}

