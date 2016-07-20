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

class CameraManager: NSObject, G8TesseractDelegate {
    let camera: GPUImageStillCamera
    let filter: GPUImageFilter = GPUImageFilter()
    weak var delegate:CameraManagerDelegate?
    let tesseract:G8Tesseract = G8Tesseract(language:"bib");
    var tessLock = NSLock()

    static let sharedInstance = CameraManager()

    override init(){
        
        // init a still image camera
        self.camera = GPUImageStillCamera()
        super.init()
        
        self.tesseract.delegate = self
        tesseract.maximumRecognitionTime = 5
        tesseract.engineMode = .TesseractOnly
        
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
        // self.debugTarget = target
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
        } else {
            
        }
        
        self.filter.useNextFrameForImageCapture()
        return  self.filter.imageFromCurrentFramebuffer()
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
            self.tessLock.lock()
            tesseract.image = image
            let didRecognize = tesseract.recognize()
            let recognizedText = tesseract.recognizedText
            self.tessLock.unlock()
            if  didRecognize == true {
                // call delegate
                self.delegate?.didProcessFrame(self, withText: recognizedText, fromSession: fromSession)
            }
        }
       
    }
 
    @objc func preprocessedImageForTesseract(tesseract: G8Tesseract!, sourceImage: UIImage!) -> UIImage! {
        // gpuimge pre-processing

        // crop
        let cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0, y: 0.05, width: 0.8, height: 0.4))
        let croppedImage = cropFilter.imageByFilteringImage(sourceImage)
        
        // re-scale
        let scaledImage = scaleImage(croppedImage, maxDimension: 640)

        // bw trheshold
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = 40.0
        cropFilter.addTarget(thresholdFilter)

        let image = thresholdFilter.imageByFilteringImage(scaledImage)
        
        return image
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