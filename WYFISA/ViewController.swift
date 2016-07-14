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
    let stillCamera = CameraManager()
    var nVerses = 0
    var captureLock: NSLock = NSLock()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // send camera to live view
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        self.stillCamera.addCameraTarget(self.filterView)
        //self.stillCamera.addDebugTarget(self.debugWindow)
        
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
        self.verseTable.appendVerse("Scanning")
        let numSections = self.verseTable.addSection()

        // start a capture event
        let captureEvent = CaptureHandler(id: numSections, camera: self.stillCamera)
        captureEvent.delegate = self
        captureEvent.recognizeFrameFromCamera()
        self.captureLock.unlock()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // when frame has been processed we need to write it back to the cell
    func didProcessFrame(sender: CaptureHandler, withText text: String, forId id: Int) {
    
       let matchedText = TextMatcher.findVersesInText(text)
        print(text, matchedText)
        
        self.captureLock.lock()
        if let text = matchedText {
            self.verseTable.updateVerseAtIndex(id-1, withText: text)
        }
        self.verseTable.reloadData()
        self.captureLock.unlock()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

