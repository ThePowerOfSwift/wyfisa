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
    var onAutoFocus: ((Void)->Void)?
    var cropFilter: GPUImageCropFilter
    
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
        
        // watches for autofocus events
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
    
    // can call autofocus method
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?,
                                         context ontext: UnsafeMutablePointer<Void>) {
        
        // process image just after finishing autofocus
        if let path = keyPath {
            if path == "adjustingFocus" {
                if let changeTo = change!["new"]  {
                    if (changeTo as! Int) == 0 {
                        if let cbFunc = self.onAutoFocus {
                            cbFunc()
                        }
                    }
                }
            }
        }
    }
}