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

}

class VerseTableViewCell: UITableViewCell {

    @IBOutlet var labelHeader: UILabel!
    @IBOutlet var labelText: UILabel!
    @IBOutlet var searchIcon: UIImageView!

    weak var delegate:VerseTableViewCellDelegate?
    var verseInfo: VerseInfo?
    let db = DBQuery.sharedInstance
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.labelHeader.textColor = UIColor.teal()

    }
    
    func updateWithVerseInfo(verse: VerseInfo, isExpanded: Bool) {

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
                self.labelHeader.textColor = UIColor.teal()
            }

        } else {
            
            self.labelHeader.textColor = UIColor.fire()
            
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
        if isExpanded == true {
            self.labelText.lineBreakMode = .ByWordWrapping
            self.labelText.numberOfLines = 0
            self.labelText.font = UIFont.init(name: "Iowan Old Style", size: 18.0)
        } else {
            self.labelText.lineBreakMode = .ByTruncatingTail
            self.labelText.numberOfLines = 1
            self.labelText.font = UIFont.init(name: "Iowan Old Style", size: 16.0)
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
            verse.chapter = chapter
            verse.refs = refs
            self.delegate?.didTapMoreButtonForCell(self, withVerseInfo: verse)
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
