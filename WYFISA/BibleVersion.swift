//
//  BibleVersion.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/13/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

enum Version: Int {
    case KJV = 0, ESV, NIV, NLT
    func text() -> String {
        switch self{
        case .KJV:
            return "kjv"
        case .ESV:
            return "esv"
        case .NIV:
            return "niv"
        case .NLT:
            return "nlt"
        }
    }
    func desc() -> String {
        switch self{
        case .KJV:
            return "King James Version"
        case .ESV:
            return "English Standard Version"
        case .NIV:
            return "New International Version"
        case .NLT:
            return "New Living Translation"
        }
    }
    
    func count() -> Int {
        return 4
    }
}
