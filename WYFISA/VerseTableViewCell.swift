//
//  VerseTableViewCell.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VerseTableViewCell: UITableViewCell {

    @IBOutlet var labelHeader: UILabel!
    @IBOutlet var labelText: UILabel!
    @IBOutlet var searchIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func updateWithVerseInfo(verse: VerseInfo, isExpanded: Bool) {

        if  verse.id.characters.count > 0 {
            // hiding icon
            self.searchIcon.alpha = 0
            self.labelHeader.alpha = 1
        } else {
            // still searching - show
            self.searchIcon.alpha = 0.6
            
            // flash searching text
            Animations.start(1){
                self.labelHeader.alpha = 0.3
            }
            
            Animations.startAfter(1, forDuration: 1){
                self.labelHeader.alpha = 1
            }
            
        }
        
        self.labelHeader.text = verse.name
        self.labelText.text = verse.text
        if isExpanded == true {
            self.labelText.lineBreakMode = .ByWordWrapping
            self.labelText.numberOfLines = 0
        } else {
            self.labelText.lineBreakMode = .ByTruncatingTail
            self.labelText.numberOfLines = 1
        }
    }
    
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
