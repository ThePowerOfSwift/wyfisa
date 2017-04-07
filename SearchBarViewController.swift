//
//  SearchBarViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/12/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class SearchBarViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FBStorageDelegate {

    let db = DBQuery.sharedInstance
    var numSections: Int = 1
    var numChapterItems: Int?
    var numVerseItems: Int?
    var selectedBook: Int?
    var selectedChapter: Int?
    var searchBarRef: UISearchBar?
    var searchView: UIView?
    var escapeImageMask: UIImageView?
    var escapeMask: UIView?
    var resultInfo: VerseInfo?
    var isVisible: Bool = false
    let themer = WYFISATheme.sharedInstance
    var firDB = FBStorage.init()
    var session: String!
    var searchMatches = [[String:AnyObject]]()
    var originalFrameSize: CGSize!

    @IBOutlet var matchLabel: UILabel!
    @IBOutlet var chapterCollection: UICollectionView!
    @IBOutlet var chapterLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.firDB.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        self.originalFrameSize = self.view.frame.size
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
        Animations.start(0.3){
            self.escapeImageMask?.hidden = false
            self.escapeImageMask?.alpha = 1
        }
        
        // theme
        self.matchLabel.textColor = self.themer.navyForLightOrWhite(1.0)
        self.chapterLabel.textColor = self.themer.navyForLightOrWhite(1.0)
        self.searchView?.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.chapterCollection.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        
        self.matchLabel.font = self.themer.currentFontAdjustedBy(10)
        self.chapterLabel.font = self.themer.currentFontAdjustedBy(10)
 
        // init session
        self.session = self.firDB.startSearchSession()
        self.searchMatches = [[String:AnyObject]]()
        
        
    }
    
    
    // MARK: - search bar delegate
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        self.firDB.updateSearchSession(self.session, text: searchText)
        if searchText == "" {
            self.searchMatches = [[String:AnyObject]]()

            // hide search view to allow user to click out
            Animations.start(0.3){
                self.searchView?.alpha = 0
            }
            
            self.view.frame.size = self.originalFrameSize

        } else {
            // text being added show view if first time
            if self.searchView?.alpha == 0 {
                Animations.start(0.3){
                    self.searchView?.alpha = 1
                }
            }
        }
        
        if searchText.length > 3 {
            if self.searchMatches.count > 0 {
                // switching to text matching if was in chapter match
                if self.numChapterItems > 0 {
                    self.setNoBookMatchAttrs()
                    self.matchLabel.text = ""
                    self.chapterCollection.reloadData()
                }
                
                // either way it goes we are in text matching mode at this point
                return
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
            self.setNoBookMatchAttrs()
        }
        
        self.chapterCollection.reloadData()
        self.matchLabel.text = label

    }
    
    func setNoBookMatchAttrs(){
        self.numChapterItems = 0
        self.numVerseItems = 0
        self.numSections = 1
        self.chapterLabel.text = ""
        self.selectedChapter = nil
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
    
    func getMatchText(row: Int) -> String {
        return self.searchMatches[row]["text"] as! String
    }
    
    func getMatchName(row: Int) -> String {
        return self.searchMatches[row]["name"]! as! String
    }
    
    func getMatchId(row: Int) -> String{
        return self.searchMatches[row]["id"] as! String
    }
    
    // MARK: - collection view
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.numSections
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            if let n = self.numChapterItems {
                if n == 0 {
                    // full text mode
                    return self.searchMatches.count
                } else if self.selectedChapter == nil {
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
        let row = indexPath.row
        
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("numcell", forIndexPath: indexPath)
        if section == 0 {
            if self.numChapterItems == 0 {
                // text cell
                cell =  collectionView.dequeueReusableCellWithReuseIdentifier("searchresult", forIndexPath: indexPath)
                let textView = cell.viewWithTag(1) as! UILabel
                let htmlText = self.getMatchText(row)

                textView.attributedText = htmlText.toHtml(themer.currentFont())
                let nameLabel = cell.viewWithTag(2) as! UILabel
                nameLabel.text = self.getMatchName(row)
                if !self.themer.isLight() {
                    textView.textColor = UIColor.teal()
                    nameLabel.textColor = UIColor.lightGrayColor()
                }
                return cell
            }
            if let ch = self.selectedChapter {
                // a chapter is selected
                cell = collectionView.dequeueReusableCellWithReuseIdentifier("numcellsmallfire", forIndexPath: indexPath)
                item = ch
            }
        }
    
        let labelView = cell.viewWithTag(1) as! UILabel
        labelView.text = "\(item+1)"
        
        // do some themeing
        if self.selectedChapter == nil || section == 1 {
            // change item color if not a fire cell
            labelView.textColor = self.themer.navyForLightOrWhite(1.0)
        }
        cell.backgroundColor = self.themer.whiteForLightOrNavy(1.0)

        if section == 0 {
            labelView.font = themer.currentFontAdjustedBy(5)
        } else {
            // verse numbers
            labelView.font = themer.currentFont()
            labelView.alpha = 0.80
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if self.numChapterItems == 0 {
            let matchId = self.getMatchId(indexPath.row)
            self.resultInfo = VerseInfo.NewVerseWithId(matchId)
            self.performSegueWithIdentifier("unwindToMain", sender: self)
            return
        }
        
        if indexPath.section == 1 {
            // verse was selected
            let bookIdStr = String(format: "%02d", self.selectedBook!)
            let chapterId = String(format: "%03d", self.selectedChapter!+1)
            let verseId = String(format: "%03d", indexPath.item+1)
            let resultId = "\(bookIdStr)\(chapterId)\(verseId)"
            let name = "\(self.matchLabel!.text!)\(self.selectedChapter!+1):\(indexPath.item+1)"

            // at least start the pull
            self.resultInfo = VerseInfo(id: resultId, name:name, text: nil)
            self.resultInfo?.bookNo = self.selectedBook
            self.resultInfo?.chapterNo = self.selectedChapter!+1
            
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

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        if self.numChapterItems == 0 {
            let width:CGFloat = collectionView.frame.width
            let height = self.themer.fontSize * 2.2
            return CGSize(width: width, height: height)
        } else {
            let offset = themer.fontSize
            let size = CGSize.init(width: 40+offset/2, height: 30+offset)
            return size
        }
    }
    
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            if let allVerses = TextMatcher().findVersesInText(searchText) {
                self.resultInfo = allVerses[0]
            }
        }
        if self.numChapterItems > 0 {
            self.performSegueWithIdentifier("unwindToMain", sender: self)
        } else {
            searchBar.resignFirstResponder()
            if let parentVC = self.parentViewController as? SearchViewController {
                self.view.frame.size.height = parentVC.view.frame.size.height * 0.8
            }
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        if self.isVisible == true && self.numChapterItems > 0 {
            self.performSegueWithIdentifier("unwindToMain", sender: self)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        self.isVisible = false
        self.escapeImageMask?.hidden = true
        self.escapeMask?.hidden = true
        
        // close out session
        self.firDB.endSearchSession(self.session)
    }
    
    func didGetMatchIDs(sender: AnyObject, matches: [AnyObject]){
        var newMatches = matches as! [[String:AnyObject]]
        var row = 0
        var reloadPaths = [NSIndexPath]()
        for match in newMatches {
            
            let id = match["id"] as! String
            newMatches[row]["name"] = VerseInfo.NewVerseWithId(id).name
            if (row+1) > self.searchMatches.count {
                row += 1
                continue // cannot compare
            }
            
            let oldText = self.searchMatches[row]["text"] as! String
            if (match["text"] as! String) != oldText {
                // just reload this row
                let path = NSIndexPath(forRow: row, inSection: 0)
                reloadPaths.append(path)
            }
            row += 1
        }
        
        let needsReload = self.searchMatches.count == 0
        let sameAffinity = self.searchMatches.count == newMatches.count
        self.searchMatches = newMatches
        if needsReload || !sameAffinity {
            self.chapterCollection.reloadData() 
        } else if (reloadPaths.count > 0) {
            self.chapterCollection.reloadItemsAtIndexPaths(reloadPaths)
        }
    }


}
