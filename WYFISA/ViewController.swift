//
//  ViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController,CaptureHandlerDelegate {

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
    var captureLock: NSLock = NSLock()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // send camera to live view
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        self.stillCamera.addCameraTarget(self.filterView)
        // self.stillCamera.addDebugTarget(self.debugWindow)
        
        // camera config
        stillCamera.zoom(1.5)
        stillCamera.focus()
        
        // start capture
        stillCamera.capture()

    }

    @IBAction func handleScreenTap(sender: AnyObject) {
        stillCamera.focus()
    }
    
    @IBAction func addRowForVerse(sender: AnyObject) {
        self.captureLock.lock()

        // adds row to verse table
        let defaultVerse = BookInfo(id: "", name: "...", text: "loading")
        self.verseTable.appendVerse(defaultVerse)
        let numSections = self.verseTable.addSection()

        // start a capture event
        let captureEvent = CaptureHandler(id: numSections, camera: self.stillCamera)
        captureEvent.delegate = self
        captureEvent.recognizeFrameFromCamera()
        self.captureLock.unlock()

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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // when frame has been processed we need to write it back to the cell
    func didProcessFrame(sender: CaptureHandler, withText text: String, forId id: Int) {
        self.captureLock.lock()
        
        print(text)
        
        if var bookInfo = TextMatcher.findVersesInText(text) {
            if let verse = db.lookupVerse(bookInfo.id){
                bookInfo.text = verse
                self.verseTable.updateVerseAtIndex(id-1, withBookInfo: bookInfo)
            }
        }
        self.verseTable.reloadData()
        self.captureLock.unlock()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

