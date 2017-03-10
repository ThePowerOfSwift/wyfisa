//
//  InfoViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/24/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import Social
import GPUImage

func defaultDoneCallback(){}

class InfoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var capturedImage: UIImageView!
    @IBOutlet var orangeBrush: UIBarButtonItem!
    @IBOutlet var redBrush: UIBarButtonItem!
    @IBOutlet var navyBrush: UIBarButtonItem!
    @IBOutlet var tmpImageView: UIImageView!
    @IBOutlet var highlightBrush: UIBarButtonItem!
    @IBOutlet var navToolbar: UIToolbar!
    
    var verseInfo: VerseInfo? = nil
    var themer = WYFISATheme.sharedInstance
    
    var doneCallback: ()->Void = defaultDoneCallback
    var originalImage: UIImage? = nil
    var frameSize: CGSize = CGSize()
    var snaphot: UIImage? = nil
    var isUpdate: Bool = false
    
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
        
        // check if editing saved image
        if self.isUpdate == true || self.snaphot != nil {
            self.capturedImage.image = self.snaphot
            self.originalImage = self.snaphot
            
            if let image = self.verseInfo?.overlayImage {
                self.tmpImageView.image = image
            }
 
        }
 
    }


    func configure(size: CGSize){
        self.frameSize = size
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    @IBAction func didPressCloseButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.doneCallback()
    }
    */
    
    @IBAction func didPressShareButton(sender: AnyObject) {
        /*
         if let vc = SLComposeViewController(forServiceType: SLServiceTypeFacebook) {
             vc.setInitialText("Look at this great picture!")
             if let image = self.makeShareImage() {
                 vc.addImage(image)
             }
             self.presentViewController(vc, animated: true, completion: nil)
         }

        // set up activity view controller
        if let text = verseInfo!.text {
            let textTruncated = text.trunc(80)
            let shareText = "\(textTruncated) (\(verseInfo!.name)) @turn2app!"
            objectsToShare.append(shareText)
        }*/

        var objectsToShare = [AnyObject]()
        if let image = self.makeShareImage() {
            objectsToShare.append(image)
        }
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityTypeAirDrop, UIActivityTypePostToFacebook ]
        
        // present the view controller
        self.presentViewController(activityViewController, animated: true, completion: nil)
 
        
    }
    
    func makeShareImage() -> UIImage? {
        
        let viewSize = self.view.bounds.size
        UIGraphicsBeginImageContext(viewSize);
        self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let screenShot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        var shareImage: UIImage? = nil
        if self.isUpdate == false { // crop
            let cropFilter = ImageFilter.cropFilter(0, y: 0.1, width: 1, height: 0.8)
            shareImage = cropFilter.imageByFilteringImage(screenShot)
        } else {
            shareImage = screenShot
        }
        
        return shareImage
    }

    @IBAction func didPressCameraButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) == true {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
    }

    /*
    @IBAction func didPressImageSelectButton(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) == true {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }*/
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.verseInfo?.image = image
        self.capturedImage.image = image
        picker.dismissViewControllerAnimated(true, completion: nil)
        if self.originalImage != nil {
            // original image was replaced, show undo
            // self.undoButton.enabled = true
        } else {
            self.originalImage = image
        }
        
        // clear out any drawing
        self.tmpImageView.image = nil
    }

    
    @IBAction func pressUndoButton(sender: AnyObject) {
        if let img = self.originalImage {
            self.capturedImage.image = img
        }
        
        self.tmpImageView.image = nil
    }
    
    
    // MARK: - Drawing
    
    @IBAction func didPressHighlightBrush(sender: AnyObject) {
        self.red = UIColor.hiRed()
        self.blue = UIColor.hiBlue()
        self.green = UIColor.hiGreen()
        self.opacity = 0.10
        self.brushWidth = 20
    }
    
    @IBAction func didPressOrangeBrush(sender: AnyObject) {
        self.red = UIColor.hiOrangeRed()
        self.blue = UIColor.hiOrangeBlue()
        self.green = UIColor.hiOrangeGreen()
        self.opacity = 0.80
        self.brushWidth = 5
    }
    
    @IBAction func didPressNavyBrush(sender: AnyObject) {
        self.red = UIColor.hiNavyRed()
        self.blue = UIColor.hiNavyBlue()
        self.green = UIColor.hiNavyGreen()
        self.opacity = 0.80
        self.brushWidth = 5
    }
    
    @IBAction func didPressRedBrush(sender: AnyObject) {
        self.red = UIColor.hiRedRed()
        self.blue = UIColor.hiRedBlue()
        self.green = UIColor.hiRedGreen()
        self.opacity = 0.80
        self.brushWidth = 5
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.swiped = false
        
        if let touch = touches.first {
            self.lastPoint = touch.locationInView(self.tmpImageView)
        }
    }
    
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        UIGraphicsBeginImageContext(self.tmpImageView.frame.size)
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
        self.verseInfo?.overlayImage = self.tmpImageView.image
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if isUpdate == false {
            self.verseInfo = VerseInfo.init(id: "0", name: "", text: nil)
            self.verseInfo?.category = .Image
        }
        self.verseInfo?.accessoryImage = self.makeShareImage()
        self.verseInfo?.overlayImage = self.tmpImageView.image
        self.verseInfo?.image = self.snaphot

    }
    
}
