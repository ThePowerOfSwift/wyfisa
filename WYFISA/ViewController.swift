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


class CameraManager: NSObject {
    var camera: GPUImageStillCamera
    var onAutoFocus: ((Void)->Void)?
    var cropFilter: GPUImageCropFilter
    
    override init(){
        // init a still image camera
        self.camera = GPUImageStillCamera()
        self.camera.outputImageOrientation = .Portrait;
        
        // setup camera filters
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = 20.0
        self.camera.addTarget(thresholdFilter)
        self.cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        thresholdFilter.addTarget(self.cropFilter)
        
        super.init()

        // watches for autofocus events
        self.camera.inputCamera.addObserver(self, forKeyPath: "adjustingFocus", options: .New, context: nil)
    }
    
    func focus(){
        // will trigger an autofocus kvo
        do {
            try camera.inputCamera.lockForConfiguration()
            camera.inputCamera.focusMode = .AutoFocus
            camera.inputCamera.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func zoom(by: CGFloat){
        // will trigger an autofocus kvo
        do {
            try camera.inputCamera.lockForConfiguration()
            camera.inputCamera.videoZoomFactor = by
            camera.inputCamera.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    // add filters and targets to camera
    func addCameraTarget(target: GPUImageInput!){
        self.camera.addTarget(target)
    }
    
    func capture(){
        self.camera.startCameraCapture()
    }
    
    func imageFromFrame() -> UIImage? {
        self.cropFilter.useNextFrameForImageCapture()
        return cropFilter.imageFromCurrentFramebuffer()
    }
    
    // can call autofocus method
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
                                         context ontext: UnsafeMutablePointer<Void>) {
        
        // process image just after finishing autofocus
        if let path = keyPath {
            if path == "adjustingFocus" {
                if let changeTo = change!["new"]  {
                    if (changeTo as! Int) == 0 {
                        if let cbFunc = self.onAutoFocus {
                            cbFunc()
                        }
                    }
                }
            }
        }
    }
}

class CaptureHandler {
    var recognizedText: String = "Searching"
    var label: UILabel
    var camera: CameraManager
    
    init(label: UILabel, camera: CameraManager){
        self.label = label
        self.camera = camera
    }
    
    func recognizeFrameFromCamera(){
        camera.onAutoFocus = self.onAutoFocus
        camera.focus()
    }
    
    func onAutoFocus(){
        // ready
        if let image = camera.imageFromFrame(){
            dispatch_async(dispatch_get_main_queue()) {
                self.processImage(image)
            }
        } else {
            print("nil")
        }
    }
    
    func processImage(image: UIImage){
        let tesseract:G8Tesseract = G8Tesseract(language:"eng");
        tesseract.image = image
        tesseract.recognize()
        print("---\n", tesseract.recognizedText)
        self.label.text = tesseract.recognizedText
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var verseTable: UITableView!
    @IBOutlet var filterView: GPUImageView!
    let stillCamera = CameraManager()
    var cropFilter = GPUImageCropFilter()
    var nVerses = 0
    var lastUiLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // send camera to live view
        self.stillCamera.addCameraTarget(self.filterView)

        let filter = GPUImageFilter()
        stillCamera.camera.addTarget(filter)
        filterView.fillMode = GPUImageFillModeType.init(2)
        
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = 20.0
        filter.addTarget(thresholdFilter)
        
        self.cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        thresholdFilter.addTarget(cropFilter)
        filter.addTarget(self.filterView)
        
        // camera config
        stillCamera.zoom(1.5)
        stillCamera.focus()
        
        // start capture
        stillCamera.capture()

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
        tesseract.recognize()
        print("---\n", tesseract.recognizedText)
       // self.lastRecognizedText = tesseract.recognizedText
    }
    
    @IBAction func addRowForVerse(sender: AnyObject) {
        
        // adds row to verse table
        self.nVerses = self.nVerses + 1

        // when table is reloaded new cells well container OCR data
        self.verseTable.reloadData()
    
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
                // this is last verse so we need to trigger ocr event
                if let view = cell.viewWithTag(1) {
                    let label = view as! UILabel
                    let event = CaptureHandler(label: label, camera: self.stillCamera)
                    event.recognizeFrameFromCamera()
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

