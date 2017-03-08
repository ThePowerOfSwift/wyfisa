//
//  VerseTableViewCell.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

protocol VerseTableViewCellDelegate: class {
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo)
    func didTapInfoButtonForVerse(verse: VerseInfo)
    func didRemoveCell(sender: VerseTableViewCell)
}

class VerseTableViewCell: UITableViewCell, FBStorageDelegate {

    @IBOutlet var labelHeader: UILabel!
    @IBOutlet var labelText: UILabel!
    @IBOutlet var searchIcon: UIImageView!
    @IBOutlet var mediaAccessory: UIImageView!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var quoteImage: UIImageView!

    weak var delegate:VerseTableViewCellDelegate?
    var verseInfo: VerseInfo?
    var enableMore: Bool = false
    let db = DBQuery.sharedInstance
    let themer = WYFISATheme.sharedInstance
    let firDB = FBStorage()


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.labelHeader.textColor = self.themer.navyForLightOrTeal(1.0)
        self.firDB.delegate = self

    }

    func highlightText() {
        let font = themer.currentFont()
        
        let attrs = [NSForegroundColorAttributeName: self.themer.fireForLightOrTurquoise(),
                     NSFontAttributeName: font]
        let attributedText = NSMutableAttributedString.init(string: self.labelText.text!, attributes: attrs)
        self.labelText.attributedText = attributedText
    }

    func applyCategoryStyle(verse: VerseInfo){
        
        // general styles
        self.mediaAccessory.hidden = true
        self.mediaAccessory.image =  nil
        self.labelHeader.lineBreakMode = .ByTruncatingTail
        self.labelHeader.numberOfLines = 1
        
        // support different cell styles
        switch verse.category {
        case .Verse:
            self.backgroundColor = self.themer.whiteForLightOrNavy(0.8)
        case .Image:
            // show accesory view
            self.mediaAccessory.hidden = false
            self.mediaAccessory.image =  verse.accessoryImage
            self.backgroundColor = UIColor.clearColor()
            self.mediaAccessory.layer.borderColor = UIColor.lightGrayColor().CGColor
        case .Note:
            // all the text is in header
            self.labelHeader.lineBreakMode = .ByWordWrapping
            self.labelHeader.numberOfLines = 0
            //self.backgroundColor = UIColor.clearColor()
            self.backgroundColor = self.themer.offWhiteForLightOrNavy(0.7)
        }
    }
    
    func updateWithVerseInfo(verse: VerseInfo, isExpanded: Bool) {

        self.applyCategoryStyle(verse)
        
        if  verse.id.characters.count > 0 {
            // cell has a verse
            self.verseInfo = verse
            
            // pull verse text matching version
            // TODO: Only when verse.version is miss-match
            firDB.getVerseDoc(verse.id)
            
            self.searchIcon.alpha = 0
            Animations.startAfter(1, forDuration: 0.2){
                self.searchIcon.alpha = 0
            }
            
            self.labelHeader.alpha = 1
            // hiding icon
            Animations.start(0.2){
                self.labelHeader.textColor = self.themer.navyForLightOrTeal(1.0)
            }

        } else {
            // still searching
            self.labelHeader.textColor = UIColor.fire()
            if self.themer.isLight() {
                self.searchIcon.image = UIImage(named: "chatbox-working-navy")
            } else {
                self.searchIcon.image = UIImage(named: "chatbox-working-white")
            }
            
            // flash search icon
            Animations.start(1){
                self.searchIcon.alpha = 0.3
            }
            
            Animations.startAfter(1, forDuration: 1){
                self.searchIcon.alpha = 1
            }
            
        }
        
        if verse.category == .Verse {
            self.labelHeader.text = verse.name
            self.labelText.text = verse.text
            self.labelText.textColor = self.themer.navyForLightOrWhite(1.0)
            self.quoteImage.hidden = true
        }
        
        if verse.category == .Note { // add opening quote
            self.labelText.text = verse.name
            self.labelHeader.text = ""
            self.labelText.layer.borderColor = UIColor.fire().CGColor
            self.quoteImage.hidden = false
        }
        
        if isExpanded == true {
            
            // show full text
            self.labelText.lineBreakMode = .ByWordWrapping
            self.labelText.numberOfLines = 0
            self.labelText.font = themer.currentFont()
            self.labelHeader.font = self.labelHeader.font.fontWithSize(themer.fontSize-3)
            
        } else {
            self.labelText.lineBreakMode = .ByTruncatingTail
            self.labelText.numberOfLines = 1
            self.labelText.font = themer.fontType.styleWithSize(16)
            self.labelHeader.font = self.labelHeader.font.fontWithSize(13)
        }

    }
    
    // MARK: - delegate
    
    @IBAction func touchOut(sender: UIButton) {
        sender.backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func touchCancel(sender: UIButton) {
        sender.backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func willSelectCellView(sender: UIButton) {
        /*
        sender.backgroundColor = UIColor.turquoise()
        Animations.startAfter(0.5, forDuration: 0.2){
            sender.backgroundColor = UIColor.clearColor()
        }
        */
    }
    
    @IBAction func didCancelCellTap(sender: UIButton) {
        // taped outside of cell
        // sender.backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func didTapCellView(sender: UIButton) {

        // append to cell
        if let verse = verseInfo {
            // start the caching and such
            let chapter = "" //db.chapterForVerse(verse.id)
            let refs = db.crossReferencesForVerse(verse.id)
            let verses = db.versesForChapter(verse.id)
            verse.chapter = chapter
            verse.refs = refs
            verse.verses = verses
            self.delegate?.didTapMoreButtonForCell(self, withVerseInfo: verse)
        }
        
    }
    @IBAction func didTapMoreButton(sender: AnyObject) {
        // append to cell
        if let verse = verseInfo {
            self.delegate?.didTapInfoButtonForVerse(verse)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    // MARK: - FIR Delegate
    func didGetSingleVerse(sender: FBStorage, verse: VerseInfo){
        self.verseInfo?.text = verse.text
        self.labelText.text = verse.text
        
        // TODO: want to update the local db record for offline support
    }
    
    func didGetVerseContext(sender: FBStorage, verses: [VerseInfo]){

    }

    
}
