//
//  ReadViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/22/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class ReadViewController: UIViewController {

    @IBOutlet var searchView: UIView!
    
    @IBOutlet var escapeMask: UIView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var escapeImageMask: UIImageView!
    
    var frameSize: CGSize = CGSize()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.frame.size = self.frameSize
    }
    
    func configure(size: CGSize){
        self.frameSize = size
    }
    @IBAction func didPressSearchButton(sender: AnyObject) {
        self.searchBar.text = nil
        self.searchView.hidden = false
        self.searchBar.hidden = false
        self.searchBar.becomeFirstResponder()
        self.escapeImageMask.hidden = false

        Animations.start(0.3){
            self.escapeImageMask.alpha = 1
        }
    }

    @IBAction func didTapEscapeWindow(sender: AnyObject) {
        if self.searchView.hidden == false {
            self.closeSearchView()
        }
    }
    
    @IBAction func unwindFromSearch(segue: UIStoryboardSegue) {
        
        self.closeSearchView()
        // add verse if matched
        let fromVC = segue.sourceViewController as! SearchBarViewController
        if let verseInfo = fromVC.resultInfo {
            /*
            verseInfo.session = self.session.currentId
            
            // new match
            self.tableDataSource?.appendVerse(verseInfo)
            dispatch_async(dispatch_get_main_queue()) {
                self.verseTable.addSection()
            }
            self.session.newMatches += 1
            self.session.matches.append(verseInfo.id)
            
            // cache
            Timing.runAfterBg(0.3){
                self.db.chapterForVerse(verseInfo.id)
                self.db.crossReferencesForVerse(verseInfo.id)
                self.db.versesForChapter(verseInfo.id)
            }
            */
        }
        
    }

    
    func closeSearchView(){
        // clean up search results
        Animations.start(0.3){
            self.searchView.alpha = 0
            self.searchBar.text = nil
            self.escapeImageMask.alpha = 0
        }

        Timing.runAfter(0.3){
            self.searchBar.endEditing(true)
            //self.searchView.hidden = true
            //self.searchBar.hidden = true
            self.escapeImageMask.hidden = true
        }
        
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "searchsegue" {
            let toVc = segue.destinationViewController as! SearchBarViewController
            toVc.escapeImageMask = self.escapeImageMask
            toVc.searchView = self.searchView
            self.searchBar.delegate = toVc
        }
    }

}
