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

   
    init(frameSize: CGSize) {
        super.init()
        self.initHeaderHeight = frameSize.height
        self.initFrameWidth = frameSize.width

    }
    
    func setCellDelegate(delegate: VerseTableViewCellDelegate){
        self.cellDelegate = delegate
    }
    
    // MARK: dataSource
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let vTableView = tableView as! VerseTableView
        
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
                verseCell.enableMore = true
                verseCell.updateWithVerseInfo(verse, isExpanded: vTableView.isExpanded)
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
                                                     font: font)+font.pointSize+25
        
        if height  > 30 { // bigger than a loading text
            height+=50
        }
        
        return height
    }

    
    // MARK: update datasource
    func appendVerse(verse: VerseInfo){
        self.recentVerses.append(verse)
        if(verse.id != ""){
            updateCellHeightVal(verse)
        }
    }
    
    
    func updateVersePending(id: Int){
        self.recentVerses[id-1].name = self.recentVerses[id-1].name+"."
    }

    func updateCellHeightVal(verse: VerseInfo){
        if let text = verse.text {
            let height = self.cellHeightForText(text, width: self.initFrameWidth)
            expandedCellHeights += height
        }
    }
    
    
    
}
