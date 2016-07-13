//
//  CaptureHandler.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import TesseractOCR

class CaptureHandler {
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
