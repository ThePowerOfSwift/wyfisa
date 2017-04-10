//
//  SessionManager.swift
//  WYFISA
//
//  Created by Tommie McAfee on 2/27/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit


class CaptureSession: NSObject {
    static let sharedInstance = CaptureSession()
    var active: Bool = false
    var currentId: UInt64 = 0
    var matches: [String] = [String]()
    var newMatches = 0
    var misses = 0
    
    func clearMatches() {
        self.matches = [String]()
    }
    func clearCache() {
        DBQuery.sharedInstance.clearCache()
    }
    func hasMatches() -> Bool {
        return self.newMatches > 0
    }
    // updates and returns old id
    func updateCaptureId() -> UInt64 {
        self.currentId += 1
        return self.currentId
    }

}
