//
//  ScriptCollection.swift
//  WYFISA
//
//  Created by Tommie McAfee on 12/1/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit


class ScriptCollection: UICollectionView, UICollectionViewDelegate, UICollectionViewDataSource {

    let themer: WYFISATheme = WYFISATheme.sharedInstance
    let storage: CBStorage = CBStorage(databaseName: "scripts")
    var displayedVerses: [VerseInfo] = [VerseInfo]()
    var lastCellID: CellIdentifier = .None
    
    required init?(coder aDecoder: NSCoder) {
        

        super.init(coder: aDecoder)
        self.delegate = self
        self.dataSource = self

    }

    func initDisplayVerses(scriptId: String){
        self.displayedVerses = [VerseInfo]()
        self.lastCellID = .None
        
        // apply layout ID's to cells
        for verse in storage.getVersesForScript(scriptId) {
            let cellID = self.lastCellID.getNextID(verse)
            verse.cellID = cellID
            
            if cellID == .Verse { // re-format
                let verseText = "\(verse.text!)  (\(verse.name))"
                verse.text = verseText
            }
            
            // if about to display a grid, make sure last image is also grided
            if cellID == .ImageGrid && self.lastCellID == .Image {
                if let lastVerse = self.displayedVerses.last {
                    lastVerse.cellID = .ImageGrid
                }
            }
            
            // combine consecutive verses & notes
            if cellID == .Verse && self.lastCellID == .Verse {
                if let lastVerse = self.displayedVerses.last {
                    lastVerse.text = "\(lastVerse.text!) \(verse.text!)"
                }
            } else if cellID == .Quote && self.lastCellID == .Quote {
                if let lastVerse = self.displayedVerses.last {
                    lastVerse.name = "\(lastVerse.name)\n\n\(verse.name)"
                }
            } else {
                self.displayedVerses.append(verse)
            }
            self.lastCellID = cellID
        }
        
        self.lastCellID = .None
        self.reloadData()
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let verse = self.displayedVerses[indexPath.row]
        let cell: UICollectionViewCell
        let cellID = verse.cellID!
        let fontOffset = cellID.getFontOffset()
        
        switch verse.category {
        case .Verse:
            let reuseId = cellID.reuseId()
            cell = self.dequeueReusableCellWithReuseIdentifier(reuseId, forIndexPath: indexPath)
            if let textView = cell.viewWithTag(1) as? UITextView {
                textView.text = verse.text!
                textView.font = themer.currentFontAdjustedBy(fontOffset)
            }
        case .Note:
            let reuseId = cellID.reuseId()
            cell = self.dequeueReusableCellWithReuseIdentifier(reuseId, forIndexPath: indexPath)
            if let labelView = cell.viewWithTag(1) as? UILabel {
                labelView.text = verse.name
                labelView.font = themer.currentFontAdjustedBy(fontOffset)
                if cellID == .Header {
                    labelView.font = ThemeFont.system(labelView.font.pointSize, weight: 0.25)
                }
            }
        case .Image:
            let reuseId = cellID.reuseId()
            cell = self.dequeueReusableCellWithReuseIdentifier(reuseId, forIndexPath: indexPath)
            if let imageView = cell.viewWithTag(1) as? UIImageView {
                imageView.image = verse.accessoryImage
                imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
            }
        }

        return cell

    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        var size:CGSize = CGSize.init(width: self.frame.width*0.90, height: 0)
        let verse = self.displayedVerses[indexPath.row]

        let cellID = verse.cellID!
        let fontOffset = cellID.getFontOffset()

        switch verse.category {
        case .Image:
            if cellID == .Image {
                size = CGSize.init(width: self.frame.width, height: self.frame.width*0.80) // todo scale accordingly
            }
            if cellID == .ImageGrid {
                size = CGSize.init(width: self.frame.width * 0.48, height: self.frame.width*0.35)
            }
        case .Note:
            var width = self.frame.width
            if cellID == .Quote {
                width = self.frame.width*0.65
            }
            let height = self.cellHeightForText(verse.name, width: width, fontOffset: fontOffset)
            size = CGSize.init(width: self.frame.width, height: height)
        case .Verse:
            if let text = verse.text {
                let height = self.cellHeightForText(text, width: self.frame.width, fontOffset: fontOffset)
                size = CGSize.init(width: self.frame.width, height: height)
            }
        }
        
        return size
    }
    
    
    func cellHeightForText(text: String, width: CGFloat, fontOffset: CGFloat) -> CGFloat {
        let font = themer.currentFontAdjustedBy(fontOffset)
        let height = text.heightWithConstrainedWidth(width*0.90,
                                                     font: font) + 30
        
        return height
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.displayedVerses.count
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func scrollToEnd(){
        let n = self.displayedVerses.count
        if n > 0 {
            let path = NSIndexPath(forRow: n-1, inSection: 0)
            self.scrollToItemAtIndexPath(path, atScrollPosition: .Bottom, animated: true)
        }
    }
    
}


// MARK - CellIdentifier
enum CellIdentifier: Int {
    case Verse = 0, Image, ImageGrid, Header, Subtitle, Quote, None
    
    func reuseId() -> String {
        switch self {
        case .Verse:
            return "scripturecell"
        case .Image:
            return "gridimagecell"
        case .ImageGrid:
            return "gridimagecell"
        case .Header:
            return "headercell"
        case .Subtitle:
            return "subtitlecell"
        case .Quote:
            return "quotecell"
        case .None:
            return ""
        }
    }
    
    // determine font adjustments for calculating heights
    func getFontOffset() -> CGFloat {
        var fontOffset:CGFloat
        switch self {
        case .Quote:
            fontOffset = -2.0
        case .Header:
            fontOffset = 8.0
        case .Subtitle:
            fontOffset = -4.0
        default:
            fontOffset = 0.0
        }
        return fontOffset
    }
    
    func getNextID(verse: VerseInfo) -> CellIdentifier {
        
        var cellID: CellIdentifier
        
        switch verse.category {
        case .Verse:
            cellID = CellIdentifier.Verse
        case .Note:
            switch self {
            case .None:
                // first note is always header
                cellID  = CellIdentifier.Header
            case .Image:
                // following image is always subtitle
                cellID = CellIdentifier.Subtitle
            case .ImageGrid:
                cellID = CellIdentifier.Subtitle
            case .Verse:
                // large following scipture is indented quote
                // as intended to be an elaboration
                if verse.name.length > 25 {
                    cellID = CellIdentifier.Quote
                } else { // make it a header
                    cellID = CellIdentifier.Header
                }
            default:
                // following quote or header
                cellID = CellIdentifier.Quote
            }
            
        case .Image:
            if self == .Image {
                cellID = CellIdentifier.ImageGrid
            } else {
                cellID = CellIdentifier.Image
            }
        }
        
        return cellID
    }
    
}
