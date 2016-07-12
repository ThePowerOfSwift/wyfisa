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
    let stillCamera: GPUImageStillCamera = GPUImageStillCamera()
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
        tesseract.pageSegmentationMode = .Auto
        tesseract.engineMode = .TesseractCubeCombined
        
        // camera config
        stillCamera.outputImageOrientation = .Portrait;
        stillCamera.jpegCompressionQuality = 10;
        
        // setup OCR enhanced filter
        //filter.blurRadiusInPixels = 20.0

        stillCamera.addTarget(filter)
        filter.addTarget(self.filterView)
        
        // start capture
        stillCamera.startCameraCapture()
        print(stillCamera.inputCamera.focusMode.rawValue)
        
        stillCamera.inputCamera.addObserver(self, forKeyPath: "adjustingFocus", options: .New, context: nil)
        
        // save photo
        captureFromCamera()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let path = keyPath {
            if path == "adjustingFocus" {
                if let changeTo = change!["new"]  {
                    if (changeTo as! Int) == 0 {
                        self.captureFromCamera()
                    }
                }
            }
        }
    }
    
    
    func captureFromCamera(){
        self.isProcessing = true
        
        self.stillCamera.capturePhotoAsImageProcessedUpToFilter(self.filter,
                                                                withCompletionHandler: { processedImage, error in




            // Give Tesseract the filtered image
            dispatch_async(dispatch_get_main_queue()) {

                if let image = processedImage {
                    let scaledImage = self.scaleImage(image, maxDimension: 240)
                    self.tesseract.image = scaledImage
                    self.tesseract.recognize()
                    //print("---\n", self.tesseract.recognizedText)
                    self.resultView.image = scaledImage
                } else {
                    print("nil day")
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

