//
//  ViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import TesseractOCR
import GPUImage

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var verseTable: UITableView!
    @IBOutlet var filterView: GPUImageView!
    let stillCamera = GPUImageStillCamera()
    var cropFilter = GPUImageCropFilter()
    var isProcessing: Bool = false
    var nVerses = 0
    var lastRecognizedText: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // send camera to live view
        stillCamera.outputImageOrientation = .Portrait;
        let filter = GPUImageFilter()
        stillCamera.addTarget(filter)
        filterView.fillMode = GPUImageFillModeType.init(2)
        
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = 20.0
        filter.addTarget(thresholdFilter)
        
        self.cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        thresholdFilter.addTarget(cropFilter)
        filter.addTarget(self.filterView)
        
        // camera config
        do {
         try stillCamera.inputCamera.lockForConfiguration()
         stillCamera.inputCamera.videoZoomFactor = 1.5
         stillCamera.inputCamera.focusMode = .AutoFocus
         stillCamera.inputCamera.unlockForConfiguration()
        } catch let error {
            print(error)
        }
        
        // start capture
        stillCamera.startCameraCapture()
        
        // observer autofocus
        stillCamera.inputCamera.addObserver(self, forKeyPath: "adjustingFocus", options: .New, context: nil)
        
        // setup tableview
        self.verseTable.delegate = self
        self.verseTable.dataSource = self
        
        
    }
    
    func readFrame(fromFilter: GPUImageCropFilter){
            fromFilter.useNextFrameForImageCapture()
            if let image = fromFilter.imageFromCurrentFramebuffer(){
                processImage(image)
            }
 
    }
    

    func processImage(image: UIImage){
        let tesseract:G8Tesseract = G8Tesseract(language:"eng");
        tesseract.image = image
        print("recognize", image.size)
        tesseract.recognize()
        print("---\n", tesseract.recognizedText)
        self.lastRecognizedText = tesseract.recognizedText
    }
    
    @IBAction func doFrameCapture(sender: AnyObject) {
        
        // do auto focus to trigger image capture
        do {
            try stillCamera.inputCamera.lockForConfiguration()
            stillCamera.inputCamera.focusMode = .AutoFocus
            stillCamera.inputCamera.unlockForConfiguration()
        } catch let error {
            print(error)
        }
        
        self.nVerses = self.nVerses + 1
        self.verseTable.reloadData()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
                                         context ontext: UnsafeMutablePointer<Void>) {
        if let path = keyPath {
            if path == "adjustingFocus" {
                if let changeTo = change!["new"]  {
                    if (changeTo as! Int) == 0 {
                        self.cropFilter.useNextFrameForImageCapture()
                        
                        if let image = self.cropFilter.imageFromCurrentFramebuffer(){
                            let asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
                            dispatch_async(asyncQueue) {
                                self.processImage(image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("verseCell"){
            if indexPath.section == self.nVerses-1 {
                // this is last verse so change text
                if let view = cell.viewWithTag(1) {
                    let label = view as! UILabel
                    label.text = self.lastRecognizedText
                }
                cell.layer.cornerRadius = 2
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.nVerses
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
}

