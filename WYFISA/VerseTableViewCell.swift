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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func load(id: Int) {
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
}
