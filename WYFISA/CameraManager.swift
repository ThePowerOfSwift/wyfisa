//
//  CameraManager.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import GPUImage
import TesseractOCR
import AVFoundation

let IS_SIMULATOR = TARGET_OS_SIMULATOR != 0

protocol CameraManagerDelegate: class {
    func didProcessFrame(sender: CameraManager, withText text: String, fromSession: UInt64)
}

class CameraManager {
    let camera: GPUImageStillCamera
    let cropFilter: GPUImageCropFilter
    weak var delegate:CameraManagerDelegate?
    static let sharedInstance = CameraManager()

    init(){
        
        // init a still image camera
        self.camera = GPUImageStillCamera()
        self.camera.outputImageOrientation = .Portrait;
        
        // setup camera filters
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = 20.0
        self.camera.addTarget(thresholdFilter)
        self.cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0.1, y: 0.05, width: 0.7, height: 0.4))
        thresholdFilter.addTarget(self.cropFilter)
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
    
    func focusIsLocked() -> Bool {
        if self.camera.inputCamera == nil {
            return false
        }
        return camera.inputCamera.focusMode == .Locked
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
    func addCameraTarget(target: GPUImageInput!){
        
        let targetView = target as! UIView
        let guassFilter = GPUImageGaussianSelectiveBlurFilter()
        guassFilter.excludeCircleRadius = targetView.superview!.frame.width/800
        guassFilter.excludeCirclePoint = CGPoint(x: 0.5, y: 0.15)
        guassFilter.aspectRatio = 1.5
        self.camera.addTarget(guassFilter)
        guassFilter.addTarget(target)

    }
    
    func addDebugTarget(target: GPUImageInput!){
        self.cropFilter.addTarget(target)
    }
    
    func capture(){
        self.camera.startCameraCapture()
    }
    
    func pause(){
        self.camera.pauseCameraCapture()
    }
    
    func resume(){
        self.camera.resumeCameraCapture()
    }
    
    func imageFromFrame() -> UIImage? {
        if(IS_SIMULATOR){
            return UIImage(named: "multiverse")
        }
        
        do {
            GPUImageContext.sharedFramebufferCache().purgeAllUnassignedFramebuffers()
            self.cropFilter.useNextFrameForImageCapture()
            return try cropFilter.imageFromCurrentFramebuffer()
        } catch {
            return nil
        }
    }
    
    func recognizeFrameFromCamera(fromSession: UInt64) {
        
        if (self.camera.inputCamera == nil ||
            self.camera.inputCamera.adjustingFocus == true) &&
            IS_SIMULATOR == false {
            // is autofocusing
            return
        }
        
        // grap frame from campera
        if let image = self.imageFromFrame(){
            
            // do image recognition
            let tesseract:G8Tesseract = G8Tesseract(language:"eng");
            tesseract.image = image
            tesseract.maximumRecognitionTime = 3.0
            if tesseract.recognize() == true {
                // call delegate
                self.delegate?.didProcessFrame(self, withText: tesseract.recognizedText, fromSession: fromSession)
            }
        }
    }
    

}