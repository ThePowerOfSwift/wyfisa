//
//  WYFISATheme.swift
//  WYFISA
//
//  Created by Tommie McAfee on 8/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

enum Scheme: Int {
    case Light = 1, Dark
}

class WYFISATheme {

    var mode: Scheme = .Light
    static let sharedInstance = WYFISATheme()
    
    func setMode(mode: Scheme) {
        self.mode = mode
    }
    
    func isLight() -> Bool {
        return self.mode == .Light
    }
    
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
