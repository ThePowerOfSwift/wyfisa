//
//  PhotoCaptureViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/9/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class PhotoCaptureViewController: UIViewController {

    @IBOutlet var photoCaptureView: GPUImageView!
    let cam = CameraManager.sharedInstance
    var frameSize = CGSize()
    var imageVerseInfo: VerseInfo? = nil
    var session = CaptureSession.sharedInstance
    let settings = SettingsManager.sharedInstance
    
    @IBOutlet var middleMask: UIView!
    @IBOutlet var middleMaskLarge: UIView!
    
    // drawing vars
    var swiped: Bool = false
    var lastPoint = CGPoint.zero
    var brushWidth: CGFloat = 20.0
    var opacity: CGFloat = 0.10
    var red = UIColor.hiRed()
    var green = UIColor.hiGreen()
    var blue = UIColor.hiBlue()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup camera
        self.photoCaptureView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
    }

    func configure(size: CGSize){
        self.frameSize = size
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
     // MARK: -CaptureButton Delegate
     func didPressCaptureButton(){
     
        self.view.frame.size = self.frameSize
        
        self.cam.addTarget(self.photoCaptureView)
         self.cam.resume()
         self.cam.printTargets()
         Animations.start(0.3){
             self.view.alpha = 1
         }
        
        if self.settings.useFlash == true {
            self.cam.torch(.On)
        }
     
     }
    

     func didReleaseCaptureButton() -> VerseInfo? {

        var rc: VerseInfo? = nil

        // save frame as image
        if let frameSnapshot = self.cam.imageFromFrame() {
            self.imageVerseInfo = VerseInfo.init(id: "0", name: "", text: nil)
            imageVerseInfo!.category = .Image
            imageVerseInfo!.image = frameSnapshot

            let yOffset:CGFloat = self.middleMaskLarge.frame.origin.y/self.frameSize.height
            let height:CGFloat = self.middleMaskLarge.frame.height/self.frameSize.height

            let cropFilter = ImageFilter.cropFilter(0, y: yOffset, width: 1, height: height)
            let croppedImage = cropFilter.imageByFilteringImage(frameSnapshot)
            imageVerseInfo!.imageCropped = croppedImage
            rc = imageVerseInfo
        }

 
        // hide camera and show underlying vc for editing frame
        Animations.start(0.3){
            self.view.alpha = 0
        }
        
        if self.settings.useFlash == true {
            self.cam.torch(.Off)
        }
        
        // pause the cam
        self.cam.pause()
        self.cam.removeTarget(self.photoCaptureView)
        
        return rc

     }
    

    
}
