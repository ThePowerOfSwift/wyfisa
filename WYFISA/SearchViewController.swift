//
//  SearchViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/25/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet var searchView: UIView!
    @IBOutlet var escapeMask: UIView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var escapeImageMask: UIImageView!
    @IBOutlet var verseText: UITextView!
    @IBOutlet var verseTitle: UILabel!
    
    let themer = WYFISATheme.sharedInstance

    var frameSize: CGSize = CGSize()
    var verseInfo: VerseInfo? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.openSearchView()
        
        // when we have verses then use last one
        if let verse = self.verseInfo {
            verseTitle.text = verse.name
            verseText.text = verse.text
        }
    }
    

    
    func openSearchView(){
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
            self.verseTitle.text = verseInfo.name
            self.verseText.text = verseInfo.text
            self.verseInfo = verseInfo
        }
        self.escapeMask.hidden = true
        
    }
    
    
    func closeSearchView(){
        self.resignFirstResponder()
        self.searchBar.endEditing(true)

        // clean up search results
        Animations.start(0.3){
            self.searchView.alpha = 0
            self.searchBar.text = nil
            self.escapeImageMask.alpha = 0
        }
        
        Timing.runAfter(0.3){
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
            self.escapeMask.hidden = false
        }
 
    }

    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

}
