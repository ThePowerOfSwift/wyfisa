//
//  NotesViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/27/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {

    @IBOutlet var buttonStack: UIStackView!
    @IBOutlet var buttonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var textView: UITextView!
    @IBOutlet var noteHeader: UILabel!

    var verseInfo: VerseInfo? = nil
    let themer = WYFISATheme.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.becomeFirstResponder()
        
        // keyboard observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        
        // colors
        self.view.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.textView.textColor = self.themer.navyForLightOrWhite(1.0)
        self.textView.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        
        // fonts
        let textFont = themer.currentFont()
        self.textView.font = textFont
        self.noteHeader.font = textFont.fontWithSize(48.0)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // Keyboard management
    // http://blog.apoorvmote.com/move-uitextfield-up-when-keyboard-appears/
    func keyboardWillShow(notification:NSNotification) {
        adjustingHeight(true, notification: notification)
    }
    
    func keyboardWillHide(notification:NSNotification) {
        adjustingHeight(false, notification: notification)
    }
    
    func adjustingHeight(show:Bool, notification:NSNotification) {
        
        
         // raise text field by increasing bottom constraint
         var userInfo = notification.userInfo!
         let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
         let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
         let changeInHeight = (CGRectGetHeight(keyboardFrame)+10) * (show ? 1 : -1)
        
         // move up buttons
         Animations.start(animationDurarion){
             self.buttonBottomConstraint.constant += changeInHeight
         }
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // close keyboard
        self.textView.resignFirstResponder()
        
        // save verse info
        if self.textView.text.length > 0 {
            let note = "“\(self.textView.text)"
            self.verseInfo = VerseInfo(id: "0", name:  note, text: nil)
        }
    }
    
    
}
