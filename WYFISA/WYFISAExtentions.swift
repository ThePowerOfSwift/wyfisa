//
//  WYFISAExtentions.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

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
}

extension UIColor {
    class func turquoise() -> UIColor {
       return UIColor.init(red: (139/255), green: (225/255), blue: (207/255), alpha: 0.80)
    }
    
    class func fire() -> UIColor {
        return UIColor.init(red: 1, green: (87/255), blue: (34/255), alpha: 1.0)
    }
    
    class func navy(alpha: CGFloat) -> UIColor {
        return UIColor.init(red: (64/255), green: (77/255), blue: (82/255), alpha: alpha)
    }
    class func teal() ->UIColor {
        return UIColor.init(red: 175/255, green: 191/255, blue: 195/255, alpha: 1.0)
    }
}