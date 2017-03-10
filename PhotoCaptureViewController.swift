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
    var session = CaptureSession.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        // setup camera
        self.photoCaptureView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        self.cam.addTarget(self.photoCaptureView)
        
        // Do any additional setup after loading the view.
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
         self.cam.resume()
         Animations.start(0.3){
             self.view.alpha = 1
         }
     
     }
    

     func didReleaseCaptureButton() -> VerseInfo? {
     
        var verseInfo:VerseInfo? = nil
        
        // save frame as image
        if let frameSnapshot = self.cam.imageFromFrame() {
            verseInfo = VerseInfo.init(id: "0", name: "", text: nil)
            verseInfo!.category = .Image
            verseInfo!.image = frameSnapshot
            verseInfo!.accessoryImage = frameSnapshot
        }

 
        // hide camera and show underlying vc for editing frame
        Animations.start(0.3){
            self.view.alpha = 0
        }
        // stop camera
        self.cam.pause()
        
         return verseInfo
     }
 
    
    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
