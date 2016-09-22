//
//  WYFISATheme.swift
//  WYFISA
//
//  Created by Tommie McAfee on 8/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

let DEFAULT_FONT_SIZE: CGFloat = 20.0

enum Scheme: Int {
    case Light = 1, Dark
}

class WYFISATheme {

    var mode: Scheme = .Light
    var fontType: ThemeFont = .Avenir
    var fontSize: CGFloat = DEFAULT_FONT_SIZE
    static let sharedInstance = WYFISATheme()
    
    func setMode(mode: Scheme) {
        self.mode = mode
    }
    
    func isLight() -> Bool {
        return self.mode == .Light
    }
    
    // font
    func currentFont() -> UIFont {
        let s = self.fontSize
        return self.fontType.styleWithSize(s)
    }
    
    func currentFontAdjustedBy(size: CGFloat) -> UIFont {
        let s = self.fontSize
        let f = self.fontType.styleWithSize(s)
        return f.fontWithSize(f.pointSize+size)
    }
    
    func setFontStyle(font: ThemeFont){
        self.fontType = font
    }
    
    func setFontSize(size: CGFloat){
        self.fontSize = size
    }
    
    // colors
    func navyForLightOrTeal(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.navy(alpha)
        default:
            return UIColor.teal()
        }
    }
    
    func offWhiteForLightOrNavy(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.offWhite(1.0)
        default:
            return UIColor.navy(1.0)
        }
    }
    func whiteForLightOrNavy(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.whiteColor()
        default:
            return UIColor.navy(1.0)
        }
    }
    
    func navyForLightOrWhite(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.navy(alpha)
        default:
            return UIColor.whiteColor()
        }
    }
    
    func navyForLightOrOffWhite(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.navy(alpha)
        default:
            return UIColor.offWhite(alpha)
        }
    }
    
    func fireForLightOrTurquoise() -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.fire()
        default:
            return UIColor.turquoise()
        }
    }
    
}
