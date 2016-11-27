//
//  ScrollViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/17/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class ScrollViewController: UIViewController, UIScrollViewDelegate, VerseTableViewCellDelegate {

    @IBOutlet var scrollView: UIScrollView!
    var captureVC: ViewController? = nil
    var pauseVC: HistoryViewController? = nil
    var commonDataSource: VerseTableDataSource? = nil
    var activePage: Int = 0
    var onPageChange: (Int) -> () = defaultCallback
    var bgCam: CameraManager = CameraManager.sharedInstance
    @IBOutlet var filterView: GPUImageView!
    var didLoad: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        let w = self.view.frame.size.width
        self.scrollView.contentSize.width = w * 3.0
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        self.captureVC = storyboard.instantiateViewControllerWithIdentifier("capturevc") as? ViewController
        self.pauseVC = storyboard.instantiateViewControllerWithIdentifier("historyvc") as? HistoryViewController

        self.captureVC?.view.frame.origin.x = 0
        self.pauseVC?.view.frame.origin.x = w

        
        // set data sources
        let ds = VerseTableDataSource(frameSize: self.view.frame.size)
        ds.cellDelegate = self
        self.captureVC?.configure(ds, isExpanded: false, size: self.view.frame.size)
        self.pauseVC?.configure(ds, isExpanded: true, size: self.view.frame.size)

        self.scrollView.addSubview(captureVC!.view)
        self.scrollView.addSubview(pauseVC!.view)
        

        // enable filter view
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        
        // put a gaussian blur on the live view
        self.bgCam.start()
        self.bgCam.addCameraBlurTargets(self.filterView)
        
    }
    override func viewDidAppear(animated: Bool) {
        if (!self.didLoad) {
            self.scrollView.contentOffset.x = 0
            self.didLoad = true
        }
    }
    
    func scrollToPage(_ page: Int){
        self.activePage = page
        
        Animations.start(0.3){
            self.scrollView.contentOffset.x = self.view.frame.size.width*CGFloat(page)
            
            // moving to pause page
            if page == 1 {
                
                // make sure cam is paused
                self.captureVC?.cam.pause()
                // make sure view is up to date
                self.pauseVC?.verseTable.reloadData()

                // scroll to end
                self.pauseVC?.verseTable.scrollToEnd()
                
            } else  {
                // resume cam on scroll to active page
                self.captureVC?.cam.resume()
                self.captureVC?.syncWithDataSource()
                self.captureVC?.verseTable.reloadData()
            }
        }
    }
    

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page =  self.scrollView.contentOffset.x/self.view.frame.size.width
        self.activePage = Int(page)

        if self.activePage == 1 {
            self.captureVC?.cam.pause()
        }
        
        self.onPageChange(self.activePage)

    }

    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        // make cam hot on moves, we can pause later
        self.captureVC?.cam.resume()
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if self.activePage == 2 {
            // going left
            self.captureVC?.syncWithDataSource()
            self.captureVC?.verseTable.reloadData()
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        

        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "VerseDetail" {
            let toVc = segue.destinationViewController as! VerseDetailModalViewController
            
            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
        }
        
        if segue.identifier == "infosegue" {
            
            let toVc = segue.destinationViewController as! InfoViewController
            let verse = sender as! VerseInfo
            toVc.verseInfo = verse
        }
    }
    
    // MARK: - cell delegate
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo){
        if sender.editing == false {
            performSegueWithIdentifier("VerseDetail", sender: (verse as! AnyObject))
        }
    }
    
    func didTapInfoButtonForVerse(verse: VerseInfo){
        performSegueWithIdentifier("infosegue", sender: (verse as! AnyObject))
    }
    
    func didRemoveCell(sender: VerseTableViewCell) {
        //print("HOTHOT")
        /*
        // update session matches to reflect new set of cells
        self.session.matches = self.verseTable.currentMatches()
        if self.session.matches.count == 0 {
            // removed all cells, exit editing mode
            self.exitEditingMode()
        }
 */
    }
    
    @IBAction func unwindFromHighlight(segue: UIStoryboardSegue) {
        //
    }

}
