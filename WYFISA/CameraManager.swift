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

enum CameraState: Int {
    case Stopped = 0, InUse, Paused
}

class SharedCameraManager {
    static let instance = SharedCameraManager()
    var cam: CameraManager? = nil
    var ready = false
    
    func prepareCamera(){
        // make sure camera is ready
        if self.ready == false {
            // we need to init the camera
            self.cam = CameraManager.init()
            if self.cam?.cameraEnabled == true {
                self.ready = true
            }
        }
    }

}

class CameraManager {
    var camera: GPUImageVideoCamera
    let filter = ImageFilter.genericFilter()
    let ocr: OCR = OCR()
    var simImage: UIImage! = UIImage(named: "oneanother")
    var state: CameraState = .Stopped
    var shouldResumeOnAppFG = false
    var cameraZoom:CGFloat = 1.0
    var cameraFocusMode: AVCaptureFocusMode = .ContinuousAutoFocus
    var cameraEnabled: Bool = false


    init(zoom:CGFloat = 1, focus:AVCaptureFocusMode = .ContinuousAutoFocus){
        
        // init a still image camera
        self.camera = GPUImageVideoCamera.init()
        self.cameraZoom = zoom
        self.cameraFocusMode = focus
        
        self.checkCameraAccess()
        if self.cameraEnabled {
            self.camera.addTarget(filter)
            self.camera.outputImageOrientation = .Portrait;
        }
        
    }
    
    func printTargets(){
        print(self.camera.targets())
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
        let guassFilter = ImageFilter.guassianBlur(0.5, y: 0, radius: 0.45)
        guassFilter.aspectRatio = 1.8
        guassFilter.blurRadiusInPixels = 8
        self.camera.addTarget(guassFilter)
        guassFilter.addTarget(target)
    }
    
    
    func addTarget(target: GPUImageInput!){
        self.camera.addTarget(target)
    }
    
    
    func removeTarget(target: GPUImageInput!){
        self.camera.removeTarget(target)
    }
    
    func removeAllTargets(){
        self.camera.removeAllTargets()
        self.camera.addTarget(filter)
    }
    
    func addDebugTarget(target: GPUImageInput!){
        // self.debugTarget = target
    }
    
    func start(){
        self.camera.startCameraCapture()
        self.zoom(self.cameraZoom)
        self.focus(self.cameraFocusMode)
        self.state = .InUse
    }
    
    func pause(){
        self.camera.pauseCameraCapture()
        self.state = .Paused
    }
    
    func resume(){
        
        // start camera if stopped, or resume
        if self.state == .Stopped {
            self.start()
        } else {
            self.camera.resumeCameraCapture()
        }
        self.state = .InUse

    }
    
    func stop(){
        self.camera.stopCameraCapture()
        self.state = .Stopped
    }
    
    func appPause(){
        self.stop()
        self.camera.removeAllTargets()
        
    }
    
    func appResume(){
        // re-init
        self.camera = GPUImageVideoCamera.init()
        self.camera.addTarget(filter)
        self.camera.outputImageOrientation = .Portrait;
        // warm up cam
        self.start()
        self.pause()
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
    
    func checkCameraAccess() {
        
        if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) !=  AVAuthorizationStatus.Authorized
        {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true
                {
                    self.cameraEnabled = true
                }
            });
        } else {
            self.cameraEnabled = true
        }
    }
    
    

}
