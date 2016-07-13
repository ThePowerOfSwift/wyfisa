//
//  CameraManager.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import GPUImage


class CameraManager: NSObject {
    var camera: GPUImageStillCamera
    var cropFilter: GPUImageCropFilter
    var onAutoFocus: Array<((Void)->Void)> = Array<((Void)->Void)>()
    var callbackLock: NSLock = NSLock()
    
    override init(){
        // init a still image camera
        self.camera = GPUImageStillCamera()
        self.camera.outputImageOrientation = .Portrait;
        
        // setup camera filters
        let thresholdFilter = GPUImageAdaptiveThresholdFilter()
        thresholdFilter.blurRadiusInPixels = 20.0
        self.camera.addTarget(thresholdFilter)
        self.cropFilter = GPUImageCropFilter(cropRegion: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        thresholdFilter.addTarget(self.cropFilter)
        
        super.init()

        // will observe auto focus events
        self.camera.inputCamera.addObserver(self, forKeyPath: "adjustingFocus", options: .New, context: nil)
        
    }
    
    func focus(){
        // will trigger an autofocus kvo
        do {
            try camera.inputCamera.lockForConfiguration()
            camera.inputCamera.focusMode = .AutoFocus
            camera.inputCamera.unlockForConfiguration()
        } catch let error {
            print(error)
        }
    }
    
    func zoom(by: CGFloat){
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
        self.camera.addTarget(target)
    }
    
    func capture(){
        self.camera.startCameraCapture()
    }
    
    func imageFromFrame() -> UIImage? {
        self.cropFilter.useNextFrameForImageCapture()
        return cropFilter.imageFromCurrentFramebuffer()
    }
    
    func addAutoFocusCallback(cbFunc: ((Void)->Void)) {
        self.callbackLock.lock()
        self.onAutoFocus.append(cbFunc)
        self.callbackLock.unlock()
    }

    // can call autofocus method
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
                                         context ontext: UnsafeMutablePointer<Void>) {
        
        // check if focus event changed to done
        if let path = keyPath {
            if path == "adjustingFocus" {
                if let changeTo = change!["new"]  {
                    if (changeTo as! Int) == 0 {
                        self.callbackLock.lock()
                        if self.onAutoFocus.isEmpty == false {
                            let cbFunc = self.onAutoFocus.removeFirst()
                            print(self.onAutoFocus.count, cbFunc)

                            cbFunc()
                        }
                        self.callbackLock.unlock()
                    }
                }
            }
        }
    }
}