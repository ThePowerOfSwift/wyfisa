//
//  ViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController, CameraManagerDelegate {

    @IBOutlet var debugWindow: GPUImageView!
    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var expandButton: UIButton!
    @IBOutlet var captureButton: UIButton!
    @IBOutlet var maskView: UIView!
    @IBOutlet var captureBox: UIImageView!
    
    let stillCamera = CameraManager()
    let db = DBQuery()
    var nVerses = 0
    var captureSessionFoundMatches: Bool = false
    var captureSessionId: UInt64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // send camera to live view
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        self.stillCamera.addCameraTarget(self.filterView)
        // self.stillCamera.addDebugTarget(self.debugWindow)
        
        // camera config
        stillCamera.zoom(1.5)
        stillCamera.focus(.AutoFocus)
        
        // start capture
        stillCamera.capture()
        stillCamera.delegate = self

    }

    @IBAction func handleScreenTap(sender: AnyObject) {
        stillCamera.focus(.AutoFocus)
    }
    
    
    @IBAction func didPressExpandButton(sender: AnyObject) {
        // expand|shrink table view
        let didExpand = self.verseTable.expandView(self.view.frame.size)
        
        // modify button image to represent state
        var buttonImage = UIImage(named: "arrow-expand")
        if didExpand == true {
            self.stillCamera.pause()
            buttonImage = UIImage(named: "arrow-expand-blue")
            UIView.animateWithDuration(0.5, animations: {
              self.captureButton.alpha = 0
              self.captureBox.alpha = 0
              self.maskView.alpha = 0.8
            })
        } else {
            self.stillCamera.resume()
            UIView.animateWithDuration(0.2, animations: {
                self.captureButton.alpha = 1
                self.captureBox.alpha = 1
                self.maskView.alpha = 0
            })
        }
        self.expandButton.setImage(buttonImage, forState: .Normal)

    }
    
    @IBAction func didPressRefreshButton(sender: AnyObject) {
        self.verseTable.clear()
        self.captureSessionId = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func didPressCaptureButton(sender: AnyObject) {
        let sessionId = self.captureSessionId

        // adds row to verse table
        let defaultVerse = VerseInfo(id: "", name: "...", text: "scanning")
        self.verseTable.appendVerse(defaultVerse)
        self.verseTable.addSection()
        
       
        // attempt in Locked Mode
        stillCamera.focus(.ContinuousAutoFocus)
        
        // capture frames
        let asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
        dispatch_async(asyncQueue) {
            while self.captureSessionId == sessionId {
                self.stillCamera.recognizeFrameFromCamera(sessionId)
            }
        }

    }

    func handleCaptureEnd(){
        stillCamera.focus(.Locked)
        self.captureSessionId += 1
        
        if self.captureSessionFoundMatches == false {
            self.verseTable.removeFailedVerse()
        }
        self.captureSessionFoundMatches = false
    }
    
    @IBAction func didReleaseCaptureButton(sender: AnyObject) {
        self.handleCaptureEnd()
    }
    @IBAction func didReleaseCaptureButtonOutside(sender: AnyObject) {
        self.handleCaptureEnd()

    }
    
    
    
    // when frame has been processed we need to write it back to the cell
    func didProcessFrame(sender: CameraManager, withText text: String, fromSession: UInt64) {
        
        if fromSession != self.captureSessionId {
            return // Ignore: from old capture session
        }
        
        let id = self.verseTable.numberOfSections
        
        if var verseInfo = TextMatcher.findVersesInText(text) {
            if let verse = self.db.lookupVerse(verseInfo.id){
                self.captureSessionFoundMatches = true
                verseInfo.text = verse
                self.verseTable.updateVerseAtIndex(id-1, withVerseInfo: verseInfo)
                self.verseTable.reloadData()
            }
        }
        
        // reload table on main queue
        dispatch_async(dispatch_get_main_queue()) {
            self.verseTable.reloadData()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}


