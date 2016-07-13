//
//  CaptureHandler.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import TesseractOCR

protocol CaptureHandlerDelegate: class {
    func didProcessFrame(sender: CaptureHandler, withText text: String, forId id: Int)
}

class CaptureHandler {
    let id: Int
    var lastCapturedText: String?
    let camera: CameraManager
    weak var delegate:CaptureHandlerDelegate?

    
    init(id: Int, camera: CameraManager){
        self.id = id
        self.camera = camera
    }
    
    func recognizeFrameFromCamera(){
        camera.addAutoFocusCallback(self.onAutoFocus)
        camera.focus()
    }
    
    func onAutoFocus(){

       // let asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
       // dispatch_async(asyncQueue) {
            // ready
            if let image = self.camera.imageFromFrame(){
                self.processImage(image)
            } else {
                print("nil frame")
            }
        //}
        
    }
    
    func processImage(image: UIImage){
        let tesseract:G8Tesseract = G8Tesseract(language:"eng");
        tesseract.image = image
        tesseract.recognize()
        //print("---\n", tesseract.recognizedText, self.label)
        self.delegate?.didProcessFrame(self, withText: tesseract.recognizedText, forId: self.id)
    }
}
