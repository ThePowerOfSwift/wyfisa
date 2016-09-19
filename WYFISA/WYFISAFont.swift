//
//  WYFISAFont.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/31/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

enum ThemeFont: Int {

    case Avenir = 0, Baskerville, Iowan, SanFrancisco

    func name() -> String {
        switch self.rawValue {
        case 0:
            return "Avenir"
        case 1:
            return "Baskerville"
        case 2:
            return "Iowan"
        default:
            return "San Francisco"
        }
    }
    
    func styleWithSize(size: CGFloat) -> UIFont {
        var font: UIFont?
        switch self.rawValue {
        case 0:
            font = UIFont.init(name: "Avenir", size: size)
        case 1:
            font = UIFont.init(name: "Baskerville", size: size)
        case 2:
            font = UIFont.init(name: "Iowan Old Style", size: size)
        default:
            font = UIFont.systemFontOfSize(size)
        }
        
        if font == nil {
            font =  UIFont.systemFontOfSize(size)
        }
        return font!
    }
    
    static func system(size: CGFloat, weight: CGFloat) -> UIFont {
        return UIFont.systemFontOfSize(size, weight: weight)
    }
}
