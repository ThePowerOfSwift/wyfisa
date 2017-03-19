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
    var doneEditingCallback:(verse: VerseInfo?) -> () = notifyImageCallback
    
    // drawing vars
    var swiped: Bool = false
    var lastPoint = CGPoint.zero
    var brushWidth: CGFloat = 20.0
    var opacity: CGFloat = 0.10
    var red = UIColor.hiRed()
    var green = UIColor.hiGreen()
    var blue = UIColor.hiBlue()
    
    @IBOutlet var tmpImageView: UIImageView!
    @IBOutlet var buttonStack: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // setup camera
        self.photoCaptureView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        
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
     
        self.buttonStack.alpha = 0
        self.tmpImageView.image = nil
        self.view.frame.size = self.frameSize
        self.cam.addTarget(self.photoCaptureView)
        
         self.cam.resume()
         Animations.start(0.3){
             self.view.alpha = 1
         }
        
        if self.settings.useFlash == true {
            self.cam.torch(.On)
        }
     
     }
    

     func didReleaseCaptureButton() {
       
        // save frame as image
        if let frameSnapshot = self.cam.imageFromFrame() {
            self.imageVerseInfo = VerseInfo.init(id: "0", name: "", text: nil)
            imageVerseInfo!.category = .Image
            let cropFilter = ImageFilter.cropFilter(0, y: 0.0, width: 1, height: 0.55)
            let croppedImage = cropFilter.imageByFilteringImage(frameSnapshot)
            imageVerseInfo!.image = croppedImage
        }

 
        // hide camera and show underlying vc for editing frame
        Animations.start(0.3){
          //  self.view.alpha = 0
            self.buttonStack.alpha = 1
        }
        

        if self.settings.useFlash == true {
            self.cam.torch(.Off)
        }

     }
    
    @IBAction func addPhotoAction(sender: AnyObject) {
        // save the overlay
        Animations.start(0.3){
            self.view.alpha = 0
        }
        // remove camera from target
        self.cam.removeTarget(self.photoCaptureView)
        
        self.doneEditingCallback(verse: self.imageVerseInfo)
        
    }
    
    @IBAction func cancelAddPhoto(sender: AnyObject) {
        Animations.start(0.3){
            self.view.alpha = 0
        }
        // remove camera from target
        self.cam.removeTarget(self.photoCaptureView)
        self.doneEditingCallback(verse: nil)

    }
 
    
    // MARK: - Drawing
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.swiped = false
        
        if let touch = touches.first {
            self.lastPoint = touch.locationInView(self.tmpImageView)
        }
    }
    
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        UIGraphicsBeginImageContextWithOptions(self.tmpImageView.frame.size, false, 0.0)
        
        let dist =  abs(fromPoint.x - toPoint.x)
        if (opacity == 0.10 && dist < 2 ){
            // gentle on highlighter ending
            self.lastPoint = fromPoint
            return
        }
        let rect = CGRect(x: 0, y: 0,
                          width: self.tmpImageView.frame.size.width,
                          height: self.tmpImageView.frame.size.height)
        self.tmpImageView.image?.drawInRect(rect)
        
        if  let context = UIGraphicsGetCurrentContext(){
            
            CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
            CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
            
            CGContextSetLineCap(context, .Square)
            CGContextSetLineWidth(context, brushWidth)
            CGContextSetRGBStrokeColor(context, red, green, blue, opacity)
            CGContextSetBlendMode(context, .Overlay)
            CGContextStrokePath(context)
        }
        
        self.tmpImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        self.swiped = true
        if let touch = touches.first {
            let currentPoint = touch.locationInView(self.tmpImageView)
            drawLineFrom(self.lastPoint, toPoint: currentPoint)
            
            self.lastPoint = currentPoint
            //   self.undoButton.enabled = true
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.imageVerseInfo?.overlayImage = self.tmpImageView.image
       // self.verseInfo?.overlayImage = self.tmpImageView.image
        //self.didModifyOverlay = true
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
