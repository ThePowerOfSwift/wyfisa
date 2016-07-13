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

class ViewController: UIViewController {

    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var resultView: UIImageView!
    let stillCamera = GPUImageStillCamera()
    let filter = GPUImageFilter()

    var isProcessing: Bool = false
    let tesseract:G8Tesseract = G8Tesseract(language:"eng");

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // send camera to live view
        stillCamera.outputImageOrientation = .Portrait;
        stillCamera.addTarget(filter)
        filterView.fillMode = GPUImageFillModeType.init(2)
        
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = 20.0
        filter.addTarget(thresholdFilter)
        
        let cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
        thresholdFilter.addTarget(cropFilter)
        filter.addTarget(self.filterView)
        
        // camera config
        do {
         try stillCamera.inputCamera.lockForConfiguration()
         stillCamera.inputCamera.videoZoomFactor = 1.5
        // stillCamera.inputCamera.focusMode = .Locked
        // stillCamera.inputCamera.setFocusModeLockedWithLensPosition(0.2, completionHandler: nil)
         stillCamera.inputCamera.unlockForConfiguration()
        } catch let error {
            print(error)
        }
        
        // start capture
        stillCamera.startCameraCapture()
        
        // read frames
        dispatch_async(dispatch_get_main_queue()) {
            while true {
                self.readFrame(cropFilter)
                sleep(1)
               GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
                G8Tesseract.clearCache()
            }
        }
    }
    
    func readFrame(fromFilter: GPUImageCropFilter){
            fromFilter.useNextFrameForImageCapture()
            if let image = fromFilter.imageFromCurrentFramebuffer(){
                processImage(image)
            }
 
    }
    

    func processImage(image: UIImage){
        self.tesseract.image = image
        print("recognize", image.size)
        self.tesseract.recognize()
        print("---\n", self.tesseract.recognizedText)
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }

}

