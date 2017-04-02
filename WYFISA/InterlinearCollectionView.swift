//
//  InterlinearCollectionView.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/30/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

var PHRASE_CACHE = [String: [StrongsEntry]]()

protocol InterlinearCollectionViewDelegate: class {
    func didSelectNewPhrase(sender: AnyObject, strongs: StrongsEntry, lexicon: LexiconEntry)
}

class InterlinearCollectionView: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegate, FBStorageDelegate {
    
    let firDB = FBStorage()
    var verseId: String!
    var footerHeight: CGFloat!
    var phrases: [StrongsEntry]? = nil
    var themer = WYFISATheme.sharedInstance
    var lexicon = LexiconData.sharedInstance
    var selectedRow: Int = 0
    weak var interlinearDelegate:InterlinearCollectionViewDelegate?


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // setup tableview
        self.delegate = self
        self.dataSource = self
        self.firDB.delegate = self
    }
    
    func loadDataForVerse(id: String){
        self.verseId = id
        if let phrases = PHRASE_CACHE[id] {
            self.phrases = phrases
            self.reloadData()
        } else {
            self.firDB.getInterlinearDoc(id)
        }
    }
    
    func setFooterHeight(height: CGFloat){
        self.footerHeight = height
    }
    
    func entryAt(row: Int) -> StrongsEntry {
        return self.phrases![row]
    }
    
    func textAt(row: Int) -> String {
        return self.phrases![row].text
    }
    
    func numberAt(row: Int) -> String {
        return self.phrases![row].number
    }
    
    func wordAt(row: Int) -> String {
        return self.phrases![row].word
    }
    
    func isLastRow(row: Int) -> Bool {
        return row == (self.numberOfItemsInSection(0) - 1)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let row = indexPath.row
        if self.isLastRow(row) {
            // footer
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("footercell", forIndexPath: indexPath)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("phrasecell", forIndexPath: indexPath)
        
        // get cell content
        let phraseText = self.textAt(row)
        let strongsNumber = self.numberAt(row)
        let wordText = self.wordAt(row)

        // get ui elements
        let phraseLabel = cell.viewWithTag(1) as! UILabel
        let numberLabel = cell.viewWithTag(2) as! UILabel
        let wordLabel = cell.viewWithTag(3) as! UILabel

        // apply content to elements
        phraseLabel.text = phraseText
        phraseLabel.font = themer.currentFont()
        phraseLabel.textColor = themer.navyForLightOrTan(1.0)

        numberLabel.text = strongsNumber.uppercaseString
        wordLabel.text = wordText
        if row == self.selectedRow {
            // highlight
            Animations.start(0.3){
                numberLabel.textColor = UIColor.fire()
                wordLabel.textColor = UIColor.fire()
                phraseLabel.textColor = UIColor.fire()
            }
        } else {
            numberLabel.textColor = UIColor.lightGrayColor()
            wordLabel.textColor = UIColor.lightGrayColor()
            phraseLabel.textColor = self.themer.navyForLightOrTan(1.0)
        }
        
        if row == self.selectedRow {
            // fetch lexicon info
            let number = self.numberAt(row)
            var testament = "hebrew"
            if number[0] == "g" {
                // greek
                testament = "greek"
            }   
            if let lexicon = self.lexicon.getEntry(testament, strongs: number) {
                let strongs = self.entryAt(row)
                self.interlinearDelegate?.didSelectNewPhrase(self,
                                                             strongs: strongs,
                                                             lexicon: lexicon)
            }

        }

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.phrases == nil {
            return 0
        }
        return self.phrases!.count+1
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        if row == self.selectedRow {
            return // same row
        }
        
        // update selected row
        let prevSelectedRow = self.selectedRow
        self.selectedRow = row
        let pathPrev = NSIndexPath.init(forRow: prevSelectedRow, inSection: 0)
        let pathCurr = NSIndexPath.init(forRow: row, inSection: 0)
        self.reloadItemsAtIndexPaths([pathPrev, pathCurr])
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let row = indexPath.row
        if self.isLastRow(row) {
            // footer
            return CGSize.init(width: self.frame.width, height: self.footerHeight)
        }
        
        let text = self.textAt(row)
        let fontSize = self.themer.fontSize
        var width = fontSize * CGFloat(text.length) * 0.55
        if width < 40 {
            width = 40
        }

        return CGSize.init(width: width, height: fontSize * 3.5)
    }
    
    func didGetSingleVerse(sender: AnyObject, verse: AnyObject) {
        if let verse  = verse as? InterlinearVerse {
            self.phrases = verse.phrases
            self.reloadData()
            
            // cache
            if PHRASE_CACHE.count > PHRASE_CACHE_MAX {
                PHRASE_CACHE =  [String: [StrongsEntry]]()
            }
            PHRASE_CACHE[self.verseId] = verse.phrases
        }
    }
    
    
}
