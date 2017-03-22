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
    
    init() {
        do {
            let db = try CBLManager.sharedInstance().databaseNamed("config")
            if let doc = db.existingDocumentWithID("settings") {
                // restore settings
                let fontID = doc.propertyForKey("font") as! Int
                if let font = ThemeFont(rawValue: fontID) {
                    self.fontType = font
                }
                self.fontSize = doc.propertyForKey("fontSize") as! CGFloat
                let nightMode = doc.propertyForKey("night") as! Bool
                if nightMode == true {
                    self.mode = .Dark
                } else {
                    self.mode = .Light
                }

            }
        } catch {}
        
    }
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
            return UIColor.offWhite(alpha)
        default:
            return UIColor.navy(alpha)
        }
    }
    func whiteForLightOrNavy(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.whiteColor()
        default:
            return UIColor.navy(alpha)
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
    
    func darkGreyForLightOrLightGrey() -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.darkTextColor()
        default:
            return UIColor.lightTextColor()
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
    
    func tanForLightOrNavy(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.tan(alpha)
        default:
            return UIColor.navy(alpha)
        }
    }
    
    func navyForLightOrTan(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
        return UIColor.navy(alpha)
        default:
        return UIColor.tan(alpha)
        }
    }
    
    func clearForLightOrNavy(alpha: CGFloat) -> UIColor {
        switch  self.mode {
        case .Light:
            return UIColor.clearColor()
        default:
            return UIColor.navy(alpha)
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
    
    func greyViewForLightOrTurquoise() -> UIView {
        let bgView = UIView.init()
        switch  self.mode {
        case .Light:
            bgView.backgroundColor = UIColor.groupTableViewBackgroundColor()
        default:
            bgView.backgroundColor = UIColor.turquoise(0.2)
        }
        return bgView
    }
    
    func statusBarStyle() -> UIStatusBarStyle {
        switch  self.mode {
        case .Light:
            return .Default
        default:
            return .LightContent
        }
    }
}
