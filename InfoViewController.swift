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
    
    @IBOutlet var middleMaskLarge: UIView!
    @IBOutlet var middleMask: UIView!
    var verseInfo: VerseInfo? = nil
    var themer = WYFISATheme.sharedInstance
    
    var doneCallback: ()->Void = defaultDoneCallback
    var originalImage: UIImage? = nil
    var frameSize: CGSize = CGSize()
    var snaphot: UIImage? = nil
    var isUpdate: Bool = false
    var didModifyOverlay: Bool = false
    
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

        }
         
    }
    
    override func viewDidAppear(animated: Bool) {
        if let yOffset = self.verseInfo?.imageCroppedOffset {
            let yOffsetVal = self.view.frame.height * yOffset
            Animations.start(0.15){
                self.middleMask.alpha = 0.15
                if yOffset >= 0 {
                    self.middleMask.center = CGPoint(x: self.view.center.x,
                                                     y: yOffsetVal)
                }
            }
        }
    }

    func imageToFile(image: UIImage, named: String){
        if let data = UIImageJPEGRepresentation(image, 0.8) {
            let filename = getDocumentsDirectory().stringByAppendingPathComponent(named)
            print(filename)
            data.writeToFile(filename, atomically: true)
        }
    }
    
    func configure(size: CGSize){
        self.frameSize = size
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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


    @IBAction func didDragHighlightMask(sender: UIPanGestureRecognizer) {
        
        self.didModifyOverlay = true
        let translation = sender.translationInView(self.view)
        let yOffsetPos = sender.view!.center.y + translation.y
        let yOffsetRatio = yOffsetPos/self.view.frame.height
        
        if (yOffsetRatio >= 0.1) && (yOffsetRatio <= 0.85) {
            sender.view!.center = CGPoint(x: sender.view!.center.x,
                                          y: yOffsetPos)
            self.middleMaskLarge.center = CGPoint(x: sender.view!.center.x,
                                                  y: yOffsetPos)
            sender.setTranslation(CGPointZero, inView: self.view)
            self.verseInfo?.imageCroppedOffset = yOffsetRatio
        }

 
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if isUpdate == false {
            self.verseInfo = VerseInfo.init(id: "0", name: "", text: nil)
            self.verseInfo?.category = .Image
        }

        if didModifyOverlay {
            // self.verseInfo?.overlayImage = self.tmpImageView.image
            let height:CGFloat = self.middleMaskLarge.frame.height/self.view.frame.height
            var yOffset:CGFloat = self.middleMaskLarge.frame.origin.y/self.view.frame.height
            if yOffset < 0 {
                yOffset = 0
            }
            let cropFilter = ImageFilter.cropFilter(0, y: yOffset, width: 1, height: height)
            self.verseInfo?.imageCropped = cropFilter.imageByFilteringImage(self.capturedImage.image)
 
        }
    }
    
}
