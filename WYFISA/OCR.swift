//
//  OCR.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import TesseractOCR
import GPUImage

class OCR: NSObject, G8TesseractDelegate {
    let tesseract:G8Tesseract = G8Tesseract(language:"eng");
    var ocrLock = NSLock()

    override init(){
        super.init()
        tesseract.maximumRecognitionTime = 20
        tesseract.engineMode = .TesseractOnly
        tesseract.pageSegmentationMode = .AutoOSD
        tesseract.delegate = self
    }
    
    func process(image: UIImage!) -> String? {

        // do image recognition
        self.ocrLock.lock()
        var recognizedText: String?

        tesseract.image = image
        if tesseract.recognize() == true {
            recognizedText = tesseract.recognizedText
        }
        
        self.ocrLock.unlock()
        return recognizedText

    }
    
    func cropScaleAndFilter(sourceImage: UIImage!) -> UIImage {
        
        // crop
        let cropFilter = ImageFilter.cropFilter(0.05, y: 0.05, width: 0.90, height: 0.30)
        let croppedImage = cropFilter.imageByFilteringImage(sourceImage)
        
        // re-scale
        let scaledImage = ImageFilter.scaleImage(croppedImage, maxDimension: 640)
        
        // threshold
        let thresholdFilter = ImageFilter.thresholdFilter(40.0)
        cropFilter.addTarget(thresholdFilter)
        let image = thresholdFilter.imageByFilteringImage(scaledImage)
        
        //self.imageToFile(image, named: "processed.jpg")
        return image
    }
    
    // gpuimge pre-processing delegate for tesseract recognize()
    @objc func preprocessedImageForTesseract(tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        return self.cropScaleAndFilter(sourceImage)
    }
    
    func imageToFile(image: UIImage, named: String){
        if let data = UIImageJPEGRepresentation(image, 0.8) {
            let filename = getDocumentsDirectory().stringByAppendingPathComponent(named)
            print(filename)
            data.writeToFile(filename, atomically: true)
        }
    }
    
}

func getDocumentsDirectory() -> NSString {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory
}
