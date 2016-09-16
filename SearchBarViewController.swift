//
//  SearchBarViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/12/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class SearchBarViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    let db = DBQuery.sharedInstance
    var numSections: Int = 1
    var numChapterItems: Int?
    var numVerseItems: Int?
    var selectedBook: Int?
    var selectedChapter: Int?
    var searchBarRef: UISearchBar?
    var searchView: UIView?
    var escapeMask: UIView?
    var resultInfo: VerseInfo?
    var isVisible: Bool = false
    
    @IBOutlet var matchLabel: UILabel!
    @IBOutlet var chapterCollection: UICollectionView!
    @IBOutlet var verseCollection: UICollectionView!
    @IBOutlet var chapterLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.numSections = 1
        self.numChapterItems = nil
        self.numVerseItems = nil
        self.matchLabel.text = nil
        self.chapterLabel.text = nil
        self.selectedChapter = nil
        self.selectedBook = nil
        self.resultInfo = nil
        self.chapterCollection.dataSource = self
        self.chapterCollection.delegate = self
        self.searchBarRef = searchBar
        self.chapterCollection.reloadData()
        self.isVisible = true
        self.escapeMask?.hidden = false
    }
    
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchText == "" {
            // exit
            self.performSegueWithIdentifier("unwindToMain", sender: self)
            return

        } else {
            // text being added show view if first time
            if self.searchView?.alpha == 0 {
                Animations.start(0.3){
                    self.searchView?.alpha = 1
                }
            }
        }
        
        let tm = TextMatcher()
        var label: String?
        
        // check if book can be found in text
        if let book = tm.findBookInText(searchText){
            
            label = book.name()+" " //spacing for chapter

            // set book and num chapters
            self.numChapterItems = book.chapters()
            self.selectedBook = book.rawValue
            
            if let selectedChapter = tm.findChapterInText(searchText){
                if let iCh = Int(selectedChapter) {
                    if searchText.containsString(":") == false {
                        self.selectChapter(iCh)
                    }
                }
            } else {
                // undo chapter selection when backspaced/cleared out
                if self.selectedChapter != nil {
                    self.deselectChapter()
                }
            }
            
        } else {
            
            // not even book is matching so clear
            self.numChapterItems = 0
            self.numVerseItems = 0
            self.numSections = 1
            self.chapterLabel.text = ""
            self.selectedChapter = nil
        }
        
        self.chapterCollection.reloadData()
        self.matchLabel.text = label

    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        if indexPath.section == 1 {
            // verse was selected
            let bookIdStr = String(format: "%02d", self.selectedBook!)
            let chapterId = String(format: "%03d", self.selectedChapter!+1)
            let verseId = String(format: "%03d", indexPath.item+1)
            let resultId = "\(bookIdStr)\(chapterId)\(verseId)"
            let name = "\(self.matchLabel!.text!)\(self.selectedChapter!+1):\(indexPath.item+1)"
            let text = self.db.lookupVerse(resultId)
            
            self.resultInfo = VerseInfo(id: resultId, name:name, text: text)

            self.performSegueWithIdentifier("unwindToMain", sender: self)
            return
        }
        
        if self.selectedChapter != nil {
            // deselecting chapter
            self.deselectChapter()
        } else {
            self.selectChapter(indexPath.item+1)
        }
        
        // reload data
        self.chapterCollection.reloadData()

    }
    
    func selectChapter(chapter: Int){
        
        // selecting chapter
        self.selectedChapter = chapter-1
        self.chapterLabel.text = "\(chapter)"
        
        // reflect in search bar
        var searchBarText = self.matchLabel.text
        if let ch = self.chapterLabel.text {
            searchBarText = searchBarText?.stringByAppendingString(ch)
        }
        self.searchBarRef?.text = searchBarText
        
        // change to 2 sections and display verses
        self.numSections = 2
        // get num chapters
        if let bookId = self.selectedBook {
            self.numVerseItems = self.db
                .numChapterVerses(bookId,
                                  chapterId: chapter)
        }
        
        // scroll to top
        let indexPath = NSIndexPath.init(forRow: 0, inSection: 0)
        self.chapterCollection.scrollToItemAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
    }
    
    func deselectChapter(){
        self.selectedChapter = nil
        self.numSections = 1
        self.numVerseItems = nil
        self.searchBarRef?.text = self.matchLabel.text
        self.chapterLabel.text = nil
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.numSections
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            if let n = self.numChapterItems {
                if self.selectedChapter == nil {
                    return n // collection of chapters
                } else {
                   return 1 // just 1 selected item
                }
            }
        }
        if section == 1 {
            if let n = self.numVerseItems {
                return n
            }
        }
        return 0
    }

    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let section = indexPath.section
        var item = indexPath.item
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("numcell", forIndexPath: indexPath)
        if section == 0 {
            if let ch = self.selectedChapter {
                // a chapter is selected
                cell = collectionView.dequeueReusableCellWithReuseIdentifier("numcellsmallfire", forIndexPath: indexPath)
                item = ch
            }
        } else {
            cell = collectionView.dequeueReusableCellWithReuseIdentifier("numcellsmall", forIndexPath: indexPath)
        }
    
        let labelView = cell.viewWithTag(1) as! UILabel
        labelView.text = "\(item+1)"

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        var size = CGSize.init(width: 50, height: 50)
        if indexPath.section == 1 {
            size.width = 30
            size.height = 30
        }
        return size
    }
    
    
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            if let allVerses = TextMatcher().findVersesInText(searchText) {
                let verseInfo = allVerses[0]
                if let text = self.db.lookupVerse(verseInfo.id) {
                    verseInfo.text = text
                    self.resultInfo = verseInfo
                }
            }
        }
        self.performSegueWithIdentifier("unwindToMain", sender: self)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if self.isVisible == true {
            self.performSegueWithIdentifier("unwindToMain", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        self.isVisible = false
        self.escapeMask?.hidden = true
    }
 
 

}
