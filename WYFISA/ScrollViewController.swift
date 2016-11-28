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
    var didLoad: Bool = false

    var bgCam: CameraManager = CameraManager.sharedInstance
    let db = DBQuery.sharedInstance

    @IBOutlet var buttonStack: UIStackView!
    @IBOutlet var filterView: GPUImageView!
    @IBOutlet var buttonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var buttonLeadingConstraint: NSLayoutConstraint!
    
    @IBOutlet var backgroundTextFieldButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        let w = self.view.frame.size.width
        self.scrollView.contentSize.width = w * 2.0
        
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
        self.commonDataSource = ds
        
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
        
        self.onPageChange(page)

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
        
        if segue.identifier == "highlightsegue" {
            let toVc = segue.destinationViewController as! InfoViewController
            // detect if this was a cell select
            if let verse = sender as? VerseInfo {
                toVc.isUpdate = true
                toVc.snaphot = verse.image
                toVc.verseInfo = verse
            }
        }
        if segue.identifier == "notesegue" {
            
            // when editing a note then pass previous text to view
            if let verse = sender as? VerseInfo {
                let toVc = segue.destinationViewController as! NotesViewController
                toVc.editingText = verse.name
                toVc.verseInfo = verse
            }
        }
        if segue.identifier == "searchsegue" {
            // give last verse from datasource
            if let ds = self.commonDataSource {
                if let verse = ds.recentVerses.last {
                    let toVc = segue.destinationViewController as! SearchViewController
                    toVc.verseInfo = verse
                }
            }
        }
    }
    
    // MARK: - cell delegate
    func didTapMoreButtonForCell(sender: VerseTableViewCell, withVerseInfo verse: VerseInfo){
        if sender.editing == false { // don't segue if cell is being edited
            switch verse.category {
            case .Verse:
                performSegueWithIdentifier("VerseDetail", sender: (verse as! AnyObject))
            case .Note:
                performSegueWithIdentifier("notesegue", sender: (verse as! AnyObject))
            case .Image:
                performSegueWithIdentifier("highlightsegue", sender: (verse as! AnyObject))
            }
        }
    }
    
    func didTapInfoButtonForVerse(verse: VerseInfo){
        performSegueWithIdentifier("infosegue", sender: (verse as! AnyObject))
    }
    
    func didRemoveCell(sender: VerseTableViewCell) {

    }
    
    @IBAction func unwindFromHighlight(segue: UIStoryboardSegue) {
        let vc = segue.sourceViewController as! InfoViewController
        
        if let verseInfo = vc.verseInfo {
            self.scrollToPage(1)

            if vc.isUpdate == false {
                // add verse to datasource
                verseInfo.session = (self.captureVC?.updateCaptureId())!
                print("NEW SESSION", verseInfo.session)
                self.commonDataSource?.appendVerse(verseInfo)
                
                // add the section to capture table and then reload pauseVC
                dispatch_async(dispatch_get_main_queue()) {
                    if let table = self.pauseVC?.verseTable {
                        table.addSection()
                    }
                    self.captureVC?.verseTable.reloadData()
                }
            }
            else {
                print("EDITED", verseInfo.session)
                // updating data at this session
                if let ds = self.commonDataSource {
                    var i = 0
                    for v in ds.recentVerses {
                        if v.session == verseInfo.session {
                            ds.recentVerses[i] = verseInfo
                            break
                        }
                        i=i+1
                    }
                }
            }
        }
        
        // resume cam if we quit
        if self.activePage == 0 {
            self.bgCam.resume()
        }
    }
    
    @IBAction func unwindFromNotes(segue: UIStoryboardSegue) {
        
        let vc = segue.sourceViewController as! NotesViewController
        
        if let verseInfo = vc.verseInfo {
            self.scrollToPage(1)

            if vc.isUpdate == false {
                // add verse to datasource
                verseInfo.session = (self.captureVC?.updateCaptureId())!
                
                self.commonDataSource?.appendVerse(verseInfo)
                
                // add the section to capture table and then reload pauseVC
                dispatch_async(dispatch_get_main_queue()) {
                    if let table = self.pauseVC?.verseTable {
                        table.addSection()
                    }
                    self.captureVC?.verseTable.reloadData()
                }
            } else {
                // updating data at this session
                if let ds = self.commonDataSource {
                    var i = 0
                    for v in ds.recentVerses {
                        if v.session == verseInfo.session {
                            ds.recentVerses[i] = verseInfo
                            break
                        }
                        i=i+1
                    }
                }
            }
        }
    }
    
    @IBAction func unwindFromSearchAndQuit(segue: UIStoryboardSegue) {
        //
    }
    @IBAction func unwindFromSearchAndSave(segue: UIStoryboardSegue) {
        // add verse to datasource
        let searchVC = segue.sourceViewController as! SearchViewController
        

        if let verseInfo = searchVC.verseInfo {
            
            self.scrollToPage(1)
            
            // add verse to datasource
            verseInfo.session = (self.captureVC?.updateCaptureId())!

             self.commonDataSource?.appendVerse(verseInfo)
            
             // add the section to capture table and then reload pauseVC
             dispatch_async(dispatch_get_main_queue()) {
                if let table = self.pauseVC?.verseTable {
                     table.addSection()
                }
                self.captureVC?.verseTable.reloadData()
             }
            
             //self.captureVC?.session.newMatches += 1
             self.captureVC?.session.matches.append(verseInfo.id)
             
             // cache
             Timing.runAfterBg(0.3){
                 self.db.chapterForVerse(verseInfo.id)
                 self.db.crossReferencesForVerse(verseInfo.id)
                 self.db.versesForChapter(verseInfo.id)
             }
        }
    }


}
