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

class ViewController: UIViewController, G8TesseractDelegate {

    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var resultView: UIImageView!
    let stillCamera = GPUImageStillCamera()
   // let filter = GPUImageAdaptiveThresholdFilter()
    let filter = GPUImageFilter()

    var isProcessing: Bool = false
    let tesseract:G8Tesseract = G8Tesseract(language:"eng");

    func example(){
        // tesseract lib init
        tesseract.delegate = self;
        
        // Grab the image you want to preprocess
        let inputImage = UIImage.init(named: "scripture.jpg")
        
        // Initialize our adaptive threshold filter
        let stillImageFilter = GPUImageAdaptiveThresholdFilter.init()
        stillImageFilter.blurRadiusInPixels = 4.0 // adjust this to tweak the blur radius of the filter, defaults to 4.0
        
        // Retrieve the filtered image from the filter
        let filteredImage = stillImageFilter.imageByFilteringImage(inputImage)
        
        // Give Tesseract the filtered image
        tesseract.image = filteredImage;
        
        tesseract.recognize()
        print(tesseract.recognizedText)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // tesseract lib init
        let tesseract:G8Tesseract = G8Tesseract(language:"eng");
        tesseract.delegate = self;
        //tesseract.pageSegmentationMode = .Auto
        //tesseract.engineMode = .TesseractCubeCombined
        
        // camera config
        stillCamera.outputImageOrientation = .Portrait;
        //stillCamera.jpegCompressionQuality = 10;
        
        // setup OCR enhanced filter
        // filter.blurRadiusInPixels = 10.0

        stillCamera.addTarget(filter)
        filter.addTarget(self.filterView)
        
        do {
         try stillCamera.inputCamera.lockForConfiguration()
         stillCamera.inputCamera.videoZoomFactor = 2.0
         stillCamera.inputCamera.focusMode = .Locked
         stillCamera.inputCamera.setFocusModeLockedWithLensPosition(0.2, completionHandler: nil)
         stillCamera.inputCamera.unlockForConfiguration()
        } catch let error {
            print(error)
        }
        
        // start capture
        stillCamera.startCameraCapture()
        
        
        // stillCamera.inputCamera.addObserver(self, forKeyPath: "adjustingFocus", options: .New, context: nil)
        
        /*
        // save photo
        captureFromCamera()
        */
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let path = keyPath {
            if path == "adjustingFocus" {
                if let changeTo = change!["new"]  {
                    if (changeTo as! Int) == 0 {
                        print(changeTo)
                        filter.useNextFrameForImageCapture()
                        
                        if let image = filter.imageFromCurrentFramebuffer(){
                            self.resultView.image = image

                            dispatch_async(dispatch_get_main_queue()) {
                                print("dispatch")
                                self.processImage(image)
                            }
                        } else {
                            print("nil")
                        }
   
            
                    }
                }
            }
        }
    }
    
    

    func processImage(image: UIImage){
       // let cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0, y: 0, width: 0.25, height: 0.25))
        let scaledImage = image // cropFilter.imageByFilteringImage(image)

        print(scaledImage.size)
        
       // self.tesseract.rect = CGRect(x: 0, y: 0, width: 200, height: 200)
        self.tesseract.image = scaledImage
        print("recognize")
        self.tesseract.recognize()
        print("---\n", self.tesseract.recognizedText)
        self.resultView.image = scaledImage

    }
    
    func captureFromCamera(){
        self.isProcessing = true
        
        self.stillCamera.capturePhotoAsImageProcessedUpToFilter(self.filter,
                                                                withCompletionHandler: { processedImage, error in




            // Give Tesseract the filtered image
            dispatch_async(dispatch_get_main_queue()) {
                if let image = processedImage {
                    self.processImage(image)
                }
            }
                                                                    
        
        })

    }
    
    func imageToFile() {
        self.stillCamera.capturePhotoAsImageProcessedUpToFilter(self.filter,
                                                                withCompletionHandler: { processedImage, error in

            let dataForJPEGFile = UIImageJPEGRepresentation(processedImage, 0.8)

            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let documentsDirectory = paths[0]
            do {
                let file = documentsDirectory.stringByAppendingString("/wyfisa.jpg")
                print(file)
                try  dataForJPEGFile?.writeToFile(file, options: .AtomicWrite)
            } catch let error {
                print("error processing image", error)
            }
        })

    }
    
    // Tesseract delegate method inside of your class
    func preprocessedImageForTesseract(tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        // sourceImage is the same image you sent to Tesseract above
        return sourceImage
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

