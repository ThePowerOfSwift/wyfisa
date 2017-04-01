//
//  VerseTableViewCell.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

enum SwipeableAction: Int {
    case Delete = 0, Add
}

protocol VerseTableViewCellDelegate: class {
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo)
    func didTapInfoButtonForVerse(verse: VerseInfo)
    func didRemoveCell(sender: VerseTableViewCell)
    func didAddCell(sender: VerseTableViewCell)
}

class VerseTableViewCell: UITableViewCell, FBStorageDelegate {

    @IBOutlet var labelHeader: UILabel!
    @IBOutlet var labelText: UILabel!
    @IBOutlet var searchIcon: UIImageView!
    @IBOutlet var mediaAccessory: UIImageView!
    @IBOutlet var moreButton: UIButton!
    @IBOutlet var quoteImage: UIImageView!
    @IBOutlet var overlayImage: UIImageView!
    @IBOutlet var highLightBar: UIView!
    @IBOutlet var textStackView: UIStackView!
    @IBOutlet var actionButton: UIButton!

    weak var delegate:VerseTableViewCellDelegate?
    var verseInfo: VerseInfo?
    var enableMore: Bool = false
    let db = DBQuery.sharedInstance
    let themer = WYFISATheme.sharedInstance
    var swipe: UISwipeGestureRecognizer? = nil
    var swipeAction: SwipeableAction = .Delete
    var isContextVerse: Bool = false
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.labelHeader.textColor = self.themer.navyForLightOrTeal(1.0)
        
        swipe = UISwipeGestureRecognizer(target: self, action: #selector(VerseTableViewCell.handleSwipe(_:)))
        swipe!.direction = .Left
        self.actionButton.hidden = true
        self.addGestureRecognizer(swipe!)
    }
    
    func handleSwipe(sender: AnyObject?){

        if self.isContextVerse { return } // cannot do action on active verse

        self.applySwipeStyle()
        if self.swipe!.direction == .Left {
            Animations.start(0.2){
                self.actionButton.hidden = false
            }
            self.swipe!.direction = .Right
        } else {
            Animations.start(0.2){
                self.actionButton.hidden = true
            }
            self.swipe!.direction = .Left
        }
    }
    
    func applySwipeStyle(){
        // apply swipe action styles
        switch self.swipeAction {
        case .Delete:
            self.actionButton.backgroundColor = UIColor.redColor()
            self.actionButton.setTitle("Delete", forState: .Normal)
            self.actionButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        case .Add:
            self.actionButton.backgroundColor = UIColor.offWhite(1.0)
            self.actionButton.setTitle("Add", forState: .Normal)
            let color = self.themer.fireForLightOrTurquoise()
            self.actionButton.setTitleColor(color, forState: .Normal)
        }
    }
    

    func highlightText() {
        Animations.start(0.2){
            let color = self.themer.fireForLightOrTurquoise()
            self.labelText.textColor = color
        }
        self.isContextVerse = true
    }

    func applyCategoryStyle(verse: VerseInfo){
        swipe!.direction = .Left
        self.actionButton.hidden = true
        
        // general styles
        self.mediaAccessory.hidden = true
        self.overlayImage.hidden = true
        self.mediaAccessory.image =  nil
        self.labelHeader.lineBreakMode = .ByTruncatingTail
        self.labelHeader.numberOfLines = 1
        self.labelText.hidden = false

        // support different cell styles
        switch verse.category {
        case .Verse:
            self.backgroundColor = self.themer.whiteForLightOrNavy(0.8)
        case .Image:
            // show accesory view
            self.mediaAccessory.hidden = false
            self.overlayImage.hidden = false
            self.mediaAccessory.image =  verse.imageCropped
            self.overlayImage.image = verse.overlayImage
            
            self.backgroundColor = UIColor.clearColor()
            self.mediaAccessory.layer.borderColor = UIColor.lightGrayColor().CGColor


        case .Note:
            // all the text is in header
            self.labelHeader.lineBreakMode = .ByWordWrapping
            self.labelHeader.numberOfLines = 0
            //self.backgroundColor = UIColor.clearColor()
            self.backgroundColor = self.themer.offWhiteForLightOrClear(1.0)
        }
        

    
    }
    
    func updateWithVerseInfo(verse: VerseInfo, isExpanded: Bool) -> Bool {

        self.applyCategoryStyle(verse)
        var needsUpdating = false
        
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
            self.quoteImage.hidden = true
            self.labelHeader.hidden = false
            self.labelText.hidden = false
            self.highLightBar.hidden = true
            self.textStackView.spacing = -20
        }
        
        if verse.category == .Image {
            self.quoteImage.hidden = true
            self.labelText.hidden = true
            self.labelHeader.hidden = true
            self.highLightBar.hidden = !verse.isHighlighted
            self.textStackView.spacing = 0
        }
        
        if verse.category == .Note {
            self.labelText.text = (verse.name)
            self.labelHeader.text = ""
            self.labelText.layer.borderColor = UIColor.fire().CGColor
            self.quoteImage.hidden = false
            self.labelText.hidden = false
            self.highLightBar.hidden = true
            self.textStackView.spacing = 0

        }

        self.labelText.textColor = self.themer.navyForLightOrOffWhite(1.0)

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
        
        return needsUpdating

    }
    
    // MARK: - delegate
    @IBAction func touchOut(sender: UIButton) {
        sender.backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func touchCancel(sender: UIButton) {
        sender.backgroundColor = UIColor.clearColor()
    }
    
    @IBAction func willSelectCellView(sender: UIButton) {
    }
    
    @IBAction func didCancelCellTap(sender: UIButton) {
    }
    
    @IBAction func didTapCellView(sender: UIButton) {

        // append to cell
        if let verse = verseInfo {
            // start the caching and such
            self.delegate?.didTapMoreButtonForCell(self, withVerseInfo: verse)
        }
        
    }
    @IBAction func didTapMoreButton(sender: AnyObject) {
        // append to cell
        if let verse = verseInfo {
            self.delegate?.didTapInfoButtonForVerse(verse)
        }
    }

    @IBAction func didTapActionButton(sender: AnyObject) {

        switch self.swipeAction {
        case .Delete:
            self.delegate?.didRemoveCell(self)
        case .Add:
            self.delegate?.didAddCell(self)
            Animations.start(0.2){
                self.actionButton.hidden = true
            }
        }
        
    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
