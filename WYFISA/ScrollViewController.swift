//
//  ScrollViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/17/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class ScrollViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var scrollView: UIScrollView!
    var captureVC: ViewController? = nil
    var pauseVC: ViewController? = nil
    var commonDataSource: VerseTableDataSource? = nil
    var activePage: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        let w = self.view.frame.size.width
        self.scrollView.contentSize.width = w * 2.0
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        self.captureVC = storyboard.instantiateViewControllerWithIdentifier("capturevc") as? ViewController
        self.pauseVC = storyboard.instantiateViewControllerWithIdentifier("capturevc") as? ViewController
        self.pauseVC?.view.frame.origin.x = w
        
        
        // set data sources
        let ds = VerseTableDataSource(frameSize: self.view.frame.size)
        self.captureVC?.configure(ds, isExpanded: false, size: self.view.frame.size)
        self.pauseVC?.configure(ds, isExpanded: true, size: self.view.frame.size)
 
        

        self.scrollView.addSubview(captureVC!.view)
        self.scrollView.addSubview(pauseVC!.view)

    }
    
    func scrollToPage(_ page: Int){
        self.activePage = page
        Animations.start(0.3){
            self.scrollView.contentOffset.x = self.view.frame.size.width*CGFloat(page)
            
            // moving to pause page
            if page == 1 {
                
                // make sure view is up to date
                self.pauseVC?.verseTable.reloadData()

                // scroll to end
                self.pauseVC?.verseTable.scrollToEnd()
                
                // make sure cam is paused
                self.captureVC?.cam?.pause()
                
            } else {
                // resume cam on scroll to active page
                self.captureVC?.cam?.resume()
            }
        }
    }
    

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page =  self.scrollView.contentOffset.x/self.view.frame.size.width
        self.activePage = Int(page)

        if self.activePage == 1 {
            self.captureVC?.cam?.pause()
        }
        
        //self.tutPager.currentPage = Int(page)
    }

    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        // make cam hot on moves, we can pause later
        self.captureVC?.cam?.resume()

    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // prepare the opposite of whichever view we are on
        if self.activePage == 0 {
            self.pauseVC?.verseTable.reloadData()
        } else {
            self.captureVC?.verseTable.reloadData()
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    }

}
