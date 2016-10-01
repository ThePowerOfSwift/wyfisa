//
//  InfoViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/24/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import Social

func defaultDoneCallback(){}

class InfoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var capturedImage: UIImageView!
    @IBOutlet var textView: UITextView!
    var verseInfo: VerseInfo? = nil
    var themer = WYFISATheme.sharedInstance
    var doneCallback: ()->Void = defaultDoneCallback
    
    @IBOutlet var navigationBar: UINavigationBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let image = self.verseInfo?.image {
            self.capturedImage.image = image
        }
        
        if let text = self.verseInfo?.text {
            let name = self.verseInfo?.name
            self.textView.text = "\(name!) -  \(text)"
            self.textView.font = themer.currentFont()
            
        }
        
        navigationBar.topItem?.title = verseInfo?.name
        
    }
    
    override func viewDidAppear(animated: Bool) {
            
        let range = NSRange.init(location: 0, length: 1)
        self.textView.scrollRangeToVisible(range)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressCloseButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.doneCallback()
    }
    
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
        
        let navOffset = self.navigationBar.frame.height/viewSize.height
        let cropFilter = ImageFilter.cropFilter(0, y: navOffset, width: 1, height: 0.9)
        let croppedImage = cropFilter.imageByFilteringImage(screenShot)
        return croppedImage
    }

    @IBAction func didPressCameraButton(sender: AnyObject) {
    
        
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) == true {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePicker.allowsEditing = false
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
    }

    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.verseInfo?.image = image
        self.capturedImage.image = image
        picker.dismissViewControllerAnimated(true, completion: nil)

 
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    /*
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let toVc = segue.destinationViewController as! ViewController
        toVc.escapeMask.hidden = true
        toVc.escapeMask.backgroundColor = UIColor.clearColor()
    }*/

}
