//
//  WYFISAFont.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/31/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

struct ThemeFonts {
    static func iowan(size: CGFloat) -> UIFont {
        if let f = UIFont.init(name: "Iowan Old Style", size: size) {
            return f
        } else {
            return UIFont.systemFontOfSize(size)
        }
    }

}