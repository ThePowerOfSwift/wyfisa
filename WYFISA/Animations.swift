//
//  Animations.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/15/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

class Timing {
    class func runAfter(ts: Double, block: dispatch_block_t){
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(ts * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue(), block)
    }
}

class Animations {
    
    
    class func start(duration: NSTimeInterval, animations: ()->Void){
        UIView.animateWithDuration(duration, animations: animations)
    }
    
    class func startAfter(ts: Double, forDuration duration: NSTimeInterval, animations: ()->Void){
        Timing.runAfter(ts){
            self.start(duration, animations: animations)
        }
    }
}