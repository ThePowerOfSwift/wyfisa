//
//  WYFISATutViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/6/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class WYFISATutViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var tutScrollView: UIScrollView!
    @IBOutlet var tutPager: UIPageControl!
    var destVC: ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tutScrollView.delegate = self
        self.tutScrollView.contentSize.width = self.view.frame.size.width * 3.0
    }

    override func viewWillAppear(animated: Bool) {
        firstLaunchTut()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressTopClose(sender: AnyObject) {
        self.fadeOutTut()
    }

    @IBAction func didPressBottomClose(sender: AnyObject) {
        self.fadeOutTut()
    }
    
    func firstLaunchTut(){
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.stringForKey("isAppAlreadyLaunchedOnce") != nil {
            // only set to bool when they've seen forecast page
            self.tutScrollView.hidden = false
            defaults.setBool(true, forKey: "isAppAlreadyLaunchedOnce")
        }
    }
    
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page =  self.tutScrollView.contentOffset.x/self.view.frame.size.width
        self.tutPager.currentPage = Int(page)

    }
    

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let max = self.view.frame.size.width  * 2 + 10
        if (scrollView.contentOffset.x > max){
            self.fadeOutTut()
        }
    }
    
    func fadeOutTut(){
        self.destVC?.capTut.hidden = false
        Animations.start(0.3){
            self.tutScrollView.alpha = 0
            self.destVC?.capTut.alpha = 0.7
        }
        Timing.runAfter(1){
            self.tutScrollView.hidden = true
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        self.destVC = segue.destinationViewController as! ViewController
    }

    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }

}
