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

class VerseTableViewCell: UITableViewCell {

    @IBOutlet var labelHeader: UILabel!
    @IBOutlet var labelText: UILabel!
    @IBOutlet var searchIcon: UIImageView!

    @IBOutlet var mediaAccessory: UIImageView!
    @IBOutlet var moreButton: UIButton!
    weak var delegate:VerseTableViewCellDelegate?
    var verseInfo: VerseInfo?
    var enableMore: Bool = false
    let db = DBQuery.sharedInstance
    let themer = WYFISATheme.sharedInstance

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.labelHeader.textColor = self.themer.navyForLightOrTeal(1.0)

    }

    func highlightText() {
        let font = themer.currentFont()
        
        let attrs = [NSForegroundColorAttributeName: self.themer.fireForLightOrTurquoise(),
                     NSFontAttributeName: font]
        let attributedText = NSMutableAttributedString.init(string: self.labelText.text!, attributes: attrs)
        self.labelText.attributedText = attributedText
    }

    func updateWithVerseInfo(verse: VerseInfo, isExpanded: Bool) {

        self.backgroundColor = self.themer.whiteForLightOrNavy(0.8)
        if self.enableMore == true {
           // no "more"
           // self.moreButton.hidden = false
        }
        if  verse.id.characters.count > 0 {
            // cell has a verse
            self.verseInfo = verse
            
            self.searchIcon.alpha = 0
            Animations.startAfter(1, forDuration: 0.2){
                self.searchIcon.alpha = 0
            }
            
            self.labelHeader.alpha = 1
            // hiding icon
            Animations.start(0.2){
                self.labelHeader.textColor = self.themer.navyForLightOrTeal(1.0)
            }
            
            
            // support for notes formating
            //   multi line header
            //   label text is date
            if verse.text == nil && verse.name.length > 0 {
                // all the text is in header
                self.labelHeader.lineBreakMode = .ByWordWrapping
                self.labelHeader.numberOfLines = 0
            } else {
                self.labelHeader.lineBreakMode = .ByTruncatingTail
                self.labelHeader.numberOfLines = 1
            }
            
            if let img = verse.accessoryImage {
                    // is accessory cell
                    self.mediaAccessory.hidden = false
                    self.mediaAccessory.image =  img
                    if isExpanded == false {
                        self.backgroundColor = UIColor.clearColor()
                    }
                
            } else {
                self.mediaAccessory.image = nil
                self.mediaAccessory.hidden = true
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
        
        self.labelHeader.text = verse.name
        self.labelText.text = verse.text
        self.labelText.textColor = self.themer.navyForLightOrWhite(1.0)
        
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
        sender.backgroundColor = UIColor.turquoise()
        Animations.startAfter(0.5, forDuration: 0.2){
            sender.backgroundColor = UIColor.clearColor()
        }
    }
    
    @IBAction func didCancelCellTap(sender: UIButton) {
        // taped outside of cell
        sender.backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func didTapCellView(sender: UIButton) {

        // append to cell
        if let verse = verseInfo {
            let chapter = db.chapterForVerse(verse.id)
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
    
}
