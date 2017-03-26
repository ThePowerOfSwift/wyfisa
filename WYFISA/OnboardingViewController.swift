//
//  OnboardingViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/25/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit
import paper_onboarding

class OnboardingViewController: UIViewController, PaperOnboardingDataSource, PaperOnboardingDelegate {

    @IBOutlet var onboardingMask: UIView!
    @IBOutlet var swipLeftGresture: UISwipeGestureRecognizer!
    @IBOutlet var swipeRightGesture: UISwipeGestureRecognizer!
    @IBOutlet var getStartedButton: UIButton!
    @IBOutlet var onboardingView: PaperOnboarding!
    override func viewDidLoad() {
        super.viewDidLoad()

        // show onboarding view
        self.onboardingView.dataSource = self
        self.onboardingView.delegate = self
        self.onboardingView.translatesAutoresizingMaskIntoConstraints = false
 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: - Datasource
    func onboardingItemAtIndex(index: Int) -> OnboardingItemInfo {

        let fire = UIColor.fire()
        let navy = UIColor.navy(1.0)
        let tan = UIColor.tan()
        let textFont = ThemeFont.Avenir.styleWithSize(40)
        let DescriptionFont = UIFont.boldSystemFontOfSize(24.0)
        
        let items:[OnboardingItemInfo] = [
            ("ios7-barcode-outline", "Scan Scripture", "Turn to references instantly by scanning", "",
                navy, fire, tan, textFont, DescriptionFont),
            ("ios7-glasses-outline-lite", "Study Context", "Study in context with Cross References", "",
                fire,tan, navy, textFont, DescriptionFont),
            ("lightbulb", "Reflect", "Add notes and reflect as you go!", "",
                UIColor.whiteColor(), fire, UIColor.navy(0.6), textFont, DescriptionFont)
        ]
        return items[index]
    }
    
    func onboardingItemsCount() -> Int {
        return 3
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    @IBAction func didSwipeRight(sender: AnyObject) {
        self.onboardingView.currentIndex(1, animated: true)
    }
    
    @IBAction func didSwipeLeft(sender: AnyObject) {
        self.performSegueWithIdentifier("unwindtoroot",
                                        sender: nil)
    }
    
    // MARK: - Delegate
    func onboardingDidTransitonToIndex(index: Int) {
        if index == 2 {
            Animations.start(1){
                self.getStartedButton.alpha = 1
            }
        }
    }
    
    func onboardingWillTransitonToIndex(index: Int) {
        if index != 2 {// quickly hide
            self.toggleEndView(false)
            Animations.start(0.3){
                self.getStartedButton.alpha = 0
            }
        } else {
            self.toggleEndView(true)
        }
    }
    
    func toggleEndView(enabled: Bool){
        self.swipLeftGresture.enabled = enabled
        self.swipeRightGesture.enabled = enabled
        self.onboardingMask.hidden = !enabled
    }

    func onboardingConfigurationItem(item: OnboardingContentViewItem, index: Int){ }


}
