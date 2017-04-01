//
//  WYFISAExtentions.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import AKPickerView_Swift

extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.max)
        
        let boundingBox = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.height
    }
    public func indexOfCharacter(char: Character) -> Int? {
        if let idx = self.characters.indexOf(char) {
            return self.startIndex.distanceTo(idx)
        }
        return nil
    }
    
    func strip(of: String) -> String{
        return self.replace(of, with: "")
    }
    
    func replace(of: String, with: String) -> String{
        return self.stringByReplacingOccurrencesOfString(of,
                                                        withString: with,
                                                        options: NSStringCompareOptions.LiteralSearch,
                                                        range: nil)
    }
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = startIndex.advancedBy(r.startIndex)
        let end = start.advancedBy(r.endIndex - r.startIndex)
        return self[Range(start ..< end)]
    }
    
    var length: Int {
        return characters.count
    }
    
    static var workingText: String {
        return "Scanning"
    }

    
    func trunc(length: Int, trailing: String? = "...") -> String {
        if self.characters.count > length {
            return self.substringToIndex(self.startIndex.advancedBy(length)) + (trailing ?? "")
        } else {
            return self
        }
    }
    
    // http://stackoverflow.com/questions/26306326/swift-apply-uppercasestring-to-only-the-first-letter-of-a-string
    func firstCharacterUpperCase() -> String {
        let lowercaseString = self.lowercaseString
        
        return lowercaseString.stringByReplacingCharactersInRange(lowercaseString.startIndex...lowercaseString.startIndex, withString: String(lowercaseString[lowercaseString.startIndex]).uppercaseString)
    }
}

extension UIColor {
    
    class func turquoise(alpha: CGFloat = 0.80) -> UIColor {
       return UIColor.init(red: (139/255), green: (225/255), blue: (207/255), alpha: alpha)
    }
    
    class func fire(alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.init(red: 1, green: (87/255), blue: (34/255), alpha: alpha)
    }
    
    class func tan(alpha: CGFloat = 1) -> UIColor {
        return UIColor.init(red: 0.921431, green: 0.921453, blue: 0.921441, alpha: alpha)
    }
    
    class func navy(alpha: CGFloat) -> UIColor {
        return UIColor.init(red: (64/255), green: (77/255), blue: (82/255), alpha: alpha)
    }
    class func teal() ->UIColor {
        return UIColor.init(red: 175/255, green: 191/255, blue: 195/255, alpha: 1.0)
    }
    class func offWhite(alpha: CGFloat) -> UIColor {
        return UIColor.init(white: 0.95, alpha: alpha)
    }
    

    // highlight Colors
    class func hiRed() ->CGFloat { return 243/255 }
    class func hiGreen() ->CGFloat { return 243/255 }
    class func hiBlue() -> CGFloat { return  21/244 }
    
    class func hiOrangeRed() ->CGFloat { return 255/255 }
    class func hiOrangeGreen() ->CGFloat { return 87/255 }
    class func hiOrangeBlue() -> CGFloat { return  34/244 }
    
    class func hiRedRed() ->CGFloat { return 205/255 }
    class func hiRedGreen() ->CGFloat { return 51/255 }
    class func hiRedBlue() -> CGFloat { return  51/244 }
    
    class func hiNavyRed() ->CGFloat { return 64/255 }
    class func hiNavyGreen() ->CGFloat { return 77/255 }
    class func hiNavyBlue() -> CGFloat { return  82/244 }
    
    
    class func highlighter(alpha: CGFloat = 1.0) -> UIColor {
        return UIColor.init(red: UIColor.hiRed(), green: UIColor.hiGreen(), blue: UIColor.hiBlue(), alpha: alpha)
    }
}

class UnderlinedLabel: UILabel {
    var isUnderlined: Bool = true
    override var text: String! {
        
        didSet {
            let textRange = NSMakeRange(0, text.length)
            let attributedText = NSMutableAttributedString(string: text)
            if self.isUnderlined == true {
                attributedText.addAttribute(NSUnderlineStyleAttributeName , value:NSUnderlineStyle.StyleSingle.rawValue, range: textRange)
                attributedText.addAttribute(NSUnderlineColorAttributeName , value:UIColor.teal(), range: textRange)
            }
            
            self.attributedText = attributedText
        }
    }
}

enum PickerViewOption: Int {
    // as ordered in pickerview
    case VerseOCR = 0, Photo
    func description() -> String {
        switch self{
        case .VerseOCR:
            return "SCAN"
        case .Photo:
            return "HIGHLIGHT"
        }
    }
}

extension AKPickerView {

    func itemToOption(item: Int) -> PickerViewOption {
        return PickerViewOption(rawValue: item) ??
            PickerViewOption.VerseOCR
    }
    func selectedOption() -> PickerViewOption {
        return self.itemToOption(self.selectedItem)
    }
    func selectItemByOption(option: PickerViewOption, animated: Bool){
        self.selectItem(option.rawValue, animated: animated)
    }
    func optionDescription(item: Int) -> String {
        let opt = self.itemToOption(item)
        return opt.description()
    }
}

// Rounded Corners
// http://stackoverflow.com/questions/34962103/how-to-set-uiimageview-with-rounded-corners-for-aspect-fit-mode
extension UIImageView
{
    func roundCornersForAspectFit(radius: CGFloat)
    {
        if let image = self.image {
            
            //calculate drawingRect
            let boundsScale = self.bounds.size.width / self.bounds.size.height
            let imageScale = image.size.width / image.size.height
            
            var drawingRect : CGRect = self.bounds
            
            if boundsScale > imageScale {
                drawingRect.size.width =  drawingRect.size.height * imageScale
                drawingRect.origin.x = (self.bounds.size.width - drawingRect.size.width) / 2
            }else{
                drawingRect.size.height = drawingRect.size.width / imageScale
                drawingRect.origin.y = (self.bounds.size.height - drawingRect.size.height) / 2
            }
            let path = UIBezierPath(roundedRect: drawingRect, cornerRadius: radius)
            let mask = CAShapeLayer()
            mask.path = path.CGPath
            self.layer.mask = mask
        }
    }
}


// random string
// http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
func randomString(length: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let len = UInt32(letters.length)
    
    var randomString = ""
    
    for _ in 0 ..< length {
        let rand = arc4random_uniform(len)
        var nextChar = letters.characterAtIndex(Int(rand))
        randomString += NSString(characters: &nextChar, length: 1) as String
    }
    
    return randomString
}

// http://stackoverflow.com/questions/40842440/swift-3-crop-image
extension UIImage {
    
    func crop(to:CGSize) -> UIImage {
        guard let cgimage = self.CGImage else { return self }
        
        let contextImage: UIImage = UIImage(CGImage: cgimage)
        
        let contextSize: CGSize = contextImage.size
        
        //Set to square
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        let cropAspect: CGFloat = to.width / to.height
        
        var cropWidth: CGFloat = to.width
        var cropHeight: CGFloat = to.height
        
        if to.width > to.height { //Landscape
            cropWidth = contextSize.width
            cropHeight = contextSize.width / cropAspect
            posY = (contextSize.height - cropHeight) / 2
        } else if to.width < to.height { //Portrait
            cropHeight = contextSize.height
            cropWidth = contextSize.height * cropAspect
            posX = (contextSize.width - cropWidth) / 2
        } else { //Square
            if contextSize.width >= contextSize.height { //Square on landscape (or square)
                cropHeight = contextSize.height
                cropWidth = contextSize.height * cropAspect
                posX = (contextSize.width - cropWidth) / 2
            }else{ //Square on portrait
                cropWidth = contextSize.width
                cropHeight = contextSize.width / cropAspect
                posY = (contextSize.height - cropHeight) / 2
            }
        }
        
        let rect: CGRect = CGRectMake(posX, posY, cropWidth, cropHeight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage!, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(CGImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        UIGraphicsBeginImageContextWithOptions(to, true, self.scale)
        cropped.drawInRect(CGRectMake(0, 0, to.width, to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized!
    }
}
