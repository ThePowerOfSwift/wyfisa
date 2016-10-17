//
//  CameraManager.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import GPUImage
import AVFoundation
import TesseractOCR

let IS_SIMULATOR = TARGET_OS_SIMULATOR != 0


class CameraManager {
    let camera: GPUImageStillCamera
    let filter = ImageFilter.genericFilter()
    let ocr: OCR = OCR()
    var simImage: UIImage! = UIImage(named: "oneanother")
    var captureStarted: Bool = false
    

    init(){
        
        // init a still image camera
        self.camera = GPUImageStillCamera()
        self.camera.addTarget(filter)
        self.camera.outputImageOrientation = .Portrait;
    }
    
    func focus(mode: AVCaptureFocusMode){
        if self.camera.inputCamera == nil {
            return
        }
        // will trigger an autofocus kvo
        do {
            try camera.inputCamera.lockForConfiguration()
            camera.inputCamera.focusMode = mode

            camera.inputCamera.unlockForConfiguration()
        } catch let error {
            print("Focus error", error)
        }
    }
    
    func focusIsMode(mode: AVCaptureFocusMode) -> Bool {
        if self.camera.inputCamera == nil {
            return false
        }
        return camera.inputCamera.focusMode == mode
    }
    
    func torch(mode: AVCaptureTorchMode){
        if self.camera.inputCamera == nil {
            return
        }
        do {
            try camera.inputCamera.lockForConfiguration()
            self.camera.inputCamera.torchMode = mode
            camera.inputCamera.unlockForConfiguration()
        } catch let error { print(error) }
    }
    
    func zoom(by: CGFloat){
        if self.camera.inputCamera  == nil {
            return
        }
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
    func addCameraBlurTargets(target: GPUImageInput!){
        
        let targetView = target as! UIView
        let guassFilter = ImageFilter.guassianBlur(0.5, y: 0.0, radius: targetView.superview!.frame.width/800)
        self.camera.addTarget(guassFilter)
        guassFilter.addTarget(target)
    }
    
    func addDebugTarget(target: GPUImageInput!){
        // self.debugTarget = target
    }
    
    func start(){
        self.camera.startCameraCapture()
        self.captureStarted = true
    }
    
    func pause(){
        self.camera.pauseCameraCapture()
    }
    
    func resume(){
        self.camera.resumeCameraCapture()
    }
    
    func setSimImage(image: UIImage){
        self.simImage = image
    }
    
    func imageFromFrame() -> UIImage? {
        if(IS_SIMULATOR){
            return self.simImage
        }
        
        self.filter.useNextFrameForImageCapture()
        return  self.filter.imageFromCurrentFramebuffer()
    }
    
    func processImage(image: UIImage) -> String? {
        return self.ocr.process(image)
    }
    
    

}
