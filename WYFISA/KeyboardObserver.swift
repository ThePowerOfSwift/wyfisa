//
//  KeyboardObserver.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/29/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//
// http://blog.apoorvmote.com/move-uitextfield-up-when-keyboard-appears/
//

import Foundation

class KeyboardObserver {
    
    var frameOffset: CGFloat = 10
    var yOffset: CGFloat = 0
    var adjustableConstraint: NSLayoutConstraint
    var originalConstraintConstant: CGFloat
    var isShowing: Bool = false
    
    init(_ observer: AnyObject, constraint: NSLayoutConstraint){
        
        self.adjustableConstraint = constraint
        self.originalConstraintConstant = constraint.constant
        
        // keyboard observers
        NSNotificationCenter
            .defaultCenter()
            .addObserver(observer,
                         selector: #selector(self.keyboardWillShow),
                         name: UIKeyboardWillShowNotification,
                         object: nil)
        NSNotificationCenter
            .defaultCenter()
            .addObserver(observer,
                         selector: #selector(self.keyboardWillHide),
                         name: UIKeyboardWillHideNotification,
                         object: nil)
    }
    
    

    @objc func keyboardWillShow(notification:NSNotification) {
        if self.isShowing == true {
            return // already showing keyboard
        }
        
        self.isShowing = true
        
        // raise text field by increasing bottom constraint
        var userInfo = notification.userInfo!
        let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let changeInHeight = (CGRectGetHeight(keyboardFrame)+self.frameOffset)  - self.yOffset
        
        // move up buttons
        Animations.start(animationDurarion){
            self.adjustableConstraint.constant += changeInHeight
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification) {
        self.adjustableConstraint.constant = self.originalConstraintConstant
        self.isShowing = false
    }

}
