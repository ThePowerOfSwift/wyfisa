//
//  WYFISATheme.swift
//  WYFISA
//
//  Created by Tommie McAfee on 8/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

let DEFAULT_FONT_SIZE: CGFloat = 18.0

enum Scheme: Int {
    case Light = 1, Dark
}

class WYFISATheme {

    var mode: Scheme = .Light
    var font: UIFont = ThemeFonts.iowan(DEFAULT_FONT_SIZE)
    static let sharedInstance = WYFISATheme()
    
    func setMode(mode: Scheme) {
        self.mode = mode
    }
    
    func isLight() -> Bool {
        return self.mode == .Light
    }
    
    // font
    func currentFont() -> UIFont {
        return self.font
    }
    
    func currentFontAdjustedBy(size: CGFloat) -> UIFont {
        let f = self.font
        return f.fontWithSize(f.pointSize+size)
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
    
    func fireForLightOrTurquoise() -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.fire()
        default:
            return UIColor.turquoise()
        }
    }
    
}
