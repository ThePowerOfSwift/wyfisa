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
    
    static func strip(str: String, of: String) -> String{
        return str.stringByReplacingOccurrencesOfString(of,
                                                     withString: "",
                                                     options: NSStringCompareOptions.LiteralSearch,
                                                     range: nil)
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