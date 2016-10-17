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
    class func runAfterBg(ts: Double, block: dispatch_block_t){
        let asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(ts * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, asyncQueue, block)
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
    class func fadeInOut(tsFadeIn: NSTimeInterval, tsFadeOut: NSTimeInterval, view: UIView, alpha: CGFloat) {

        if view.alpha != 0.0 {
            return // already transitioning
        }
        
        Animations.start(tsFadeIn){
            view.alpha = alpha
        }
        
        Animations.startAfter(tsFadeIn,
                              forDuration: tsFadeOut){
            view.alpha = 0
        }
        
    }
    class func fadeOutIn(tsFadeIn: NSTimeInterval, tsFadeOut: NSTimeInterval, view: UIView, alpha: CGFloat) {
        
        if view.alpha != 1.0 {
            return // already transitioning
        }
        
        Animations.start(tsFadeIn){
            view.alpha = alpha
        }
        
        Animations.startAfter(tsFadeIn,
                              forDuration: tsFadeOut){
                                view.alpha = 1
        }
        
    }
}
