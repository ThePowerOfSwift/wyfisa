//
//  VerseTableDataSource.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/17/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VerseTableDataSource: NSObject, UITableViewDataSource {

    
    var nVerses: Int = 0
    var nVersesOffset: Int = 0
    var expandedCellHeights: CGFloat = 0.0
    var recentVerses: [VerseInfo] = [VerseInfo]()
    var initHeaderHeight: CGFloat = 0
    var initFrameWidth: CGFloat = 0
    var hasHeader: Bool = true
    var cellDelegate: VerseTableViewCellDelegate?
    var themer = WYFISATheme.sharedInstance
    var storage = CBStorage.init(databaseName: SCRIPTS_DB)
    var ephemeral: Bool = false
    
    init(frameSize: CGSize, scriptId: String?, ephemeral: Bool = false) {
        super.init()
        self.initHeaderHeight = frameSize.height
        self.initFrameWidth = frameSize.width
        if ephemeral == false {
            if let id = scriptId {
                self.recentVerses = storage.getVersesForScript(id)
            }
        }
        self.ephemeral = ephemeral
        self.nVerses = self.recentVerses.count
    }
    
    func setCellDelegate(delegate: VerseTableViewCellDelegate){
        self.cellDelegate = delegate
    }
    
    // MARK: dataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let vTableView = tableView as! VerseTableView
        vTableView.separatorColor = UIColor.clearColor()
        
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
                let verse = self.recentVerses[index]
                verseCell.enableMore = vTableView.isExpanded == true
                verseCell.updateWithVerseInfo(verse, isExpanded: vTableView.isExpanded)
                verseCell.resetDeleteMode()
    
                return verseCell
            }
        }
        return VerseTableViewCell(style: .Default, reuseIdentifier: nil)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.nVerses + 1
    }

    func cellHeightForText(text: String, width: CGFloat) -> CGFloat {
        let font = themer.currentFont()
        var height = text.heightWithConstrainedWidth(width*0.90,
                                                     font: font)+font.pointSize
        
        if height  > 30 { // bigger than a loading text
            height+=50
        }
        
        return height
    }

    // MARK: update datasource
    func appendVerse(verse: VerseInfo){
        self.recentVerses.append(verse)
        if(verse.id != ""){
            // is actual verse
            updateCellHeightVal(verse)
            if self.ephemeral == false {
                self.storage.putVerse(verse)
            }
        }
    }


    func updateVersePending(id: Int){
        self.recentVerses[id-1].name = self.recentVerses[id-1].name+"."
    }

    func updateRecentVerse(verse: VerseInfo){
        var i = 0
        for v in self.recentVerses {
            if v.session == verse.session {
                self.recentVerses[i] = verse
                if self.ephemeral == false {
                    self.storage.updateVerse(verse)
                }
                break
            }
            i=i+1
        }
    }

    func updateCellHeightVal(verse: VerseInfo){
        if let text = verse.text {
            let height = self.cellHeightForText(text, width: self.initFrameWidth)
            expandedCellHeights += height
        }
    }

    func getLastVerseItem() -> VerseInfo? {
        for v in self.recentVerses.reverse() {
            if v.category == .Verse {
                return v
            }
        }
        return nil
    }

    func getMaxSessionID() -> UInt64 {
        var maxId:UInt64 = 0
        for verse in self.recentVerses {
            if verse.session > maxId {
                maxId = verse.session
            }
        }
        return maxId+1
    }
    
    func getSectionForKey(key: String) -> Int {
        var i = 0
        for verse in self.recentVerses {
            if verse.key == key {
                break
            }
            i++
        }
        return i
    }
    
    func removeSection(section: Int) {
        // remove from storage
        let verseKey = self.recentVerses[section].key
        self.storage.removeDoc(verseKey)
        
        // delete cell from datasource
        self.nVerses -= 1
        self.recentVerses.removeAtIndex(section)

    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {
            
            // remove from storage
            let verseKey = self.recentVerses[indexPath.section-1].key
            self.storage.removeDoc(verseKey)

            // delete cell from datasource
            self.nVerses -= 1
            self.recentVerses.removeAtIndex(indexPath.section-1)
            
            // notify cell delegate of removed content
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! VerseTableViewCell
            cell.delegate?.didRemoveCell(cell)
            
            // drop celll from section
            print(indexPath.section)
            if indexPath.section > 1 {
                let idxSet = NSIndexSet(index: indexPath.section)
                tableView.deleteSections(idxSet, withRowAnimation: .Automatic)
            }
            tableView.reloadData()
        }
    }
}
