//
//  WYFISATests.swift
//  WYFISATests
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import XCTest
import Regex

@testable import WYFISA



    
class WYFISATests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: BookData
    func testBookDataLoaded(){
        let booksData = BooksData.sharedInstance
        XCTAssert(booksData.data.count == 66)
    }
    
    func testBookDataLoadedJson(){
        let booksData = BooksData.sharedInstance
        let firstBook = booksData.data[0]["n"]
        XCTAssert(firstBook != nil)
        XCTAssert(firstBook! as! String == "Genesis")
        
        let lastBook = booksData.data[65]["n"]
        XCTAssert(lastBook != nil)
        XCTAssert(lastBook! as! String == "Revelation")
    }
    
    
    // MARK: Books
    func testHasAllBooks() {

        // 66 total books
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book != nil)
        }
        
        // not 67
        let book = Books.init(rawValue: 67)
        XCTAssert(book == nil)
    }

    func testAllBooksHaveName() {
        
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book?.name() != nil)
        }
    }
    
    func testBookNames() {
        XCTAssert(Books.Gen.name() == "Genesis")
        XCTAssert(Books.Gal.name() == "Galatians", Books.Gal.name())
        XCTAssert(Books.Cor2.name() == "2 Corinthians", Books.Cor2.name())
        XCTAssert(Books.Rev.name() == "Revelation", Books.Rev.name())
    }
    

    // MARK: DBQuery
    func testDbLookupVerse(){
        let db = DBQuery()
        let verseText = db.lookupVerse("43014006") //John 14:6
        XCTAssert(verseText != nil)
        let expectedText = "Jesus said to him, \"I am the way, the truth, and the life. No one comes to the Father, except through me."
        XCTAssert(verseText == expectedText)
    }
    
    func testDbLookupVerseHasChapter(){
        let db = DBQuery()
        let chapterText = db.chapterForVerse("43014006")
        XCTAssert(chapterText.length > 0)
        let verseText = "Jesus said to him, \"I am the way, the truth, and the life. No one comes to the Father, except through me."
        XCTAssert(chapterText.containsString(verseText))
    }
    
    func testDbVerseHasCrossReference(){
        let db = DBQuery()
        let crossRefs = db.crossReferencesForVerse("43014006")
        XCTAssert(crossRefs.count > 0)
    }
    
    // MARK: OCR
    func testRecognizeMultiverseImage(){
        let ocr = OCR()
        let image = UIImage(named: "multiverse")
        let text = ocr.process(image)
        print(text)
        XCTAssert(text != nil)
        if let allVerses = TextMatcher().findVersesInText(text!) {
            XCTAssert(allVerses.count == 2)
            XCTAssert(allVerses[0].name == "1 Peter 3:22")
            XCTAssert(allVerses[1].name == "1 Corinthians 15:28")
        } else {
            XCTFail("expected verses")
        }

    }
    // MARK: OCR
    func testRecognizeOneAnotherImage(){
        let ocr = OCR()
        let image = UIImage(named: "oneanother")
        let filteredImage = ocr.cropScaleAndFilter(image!)
        let text = ocr.process(filteredImage)
        XCTAssert(text != nil)
        print("TEXT", text)
        if let allVerses = TextMatcher().findVersesInText(text!) {
            print(allVerses.count)
        } else {
            XCTFail("expected verses")
        }
        
    }
    
    // MARK: DB Perf
    func testPerformanceFetchVerse() {
        // This is an example of a performance test case.
        self.measureBlock {
            DBQuery.sharedInstance.lookupVerse("43014006")
        }
    }
    func testPerformanceFetchChapter() {
        // This is an example of a performance test case.
        self.measureBlock {
            DBQuery.sharedInstance.chapterForVerse("43014006")
        }
    }
    func testPerformanceFetchRferences() {
        // This is an example of a performance test case.
        self.measureBlock {
            DBQuery.sharedInstance.crossReferencesForVerse("43014006")
        }
    }
    
    // MARK: Filter Perf
    func testPerformanceCropImage() {
        let image = UIImage(named: "multiverse")
        let cropFilter = ImageFilter.cropFilter(0, y: 0.05, width: 0.8, height: 0.4)
        self.measureBlock {
            // crop
            cropFilter.imageByFilteringImage(image)
        }
    }
    func testPerformanceScale() {
        let image = UIImage(named: "multiverse")
        self.measureBlock {
            ImageFilter.scaleImage(image!, maxDimension: 640)
        }
    }
    func testPerformanceApplyThresholdImage() {
        let image = UIImage(named: "multiverse")
        let thresholdFilter = ImageFilter.thresholdFilter(10.0)
        self.measureBlock {
            thresholdFilter.imageByFilteringImage(image)
        }
    }
    func testPermanceScropScaleAndThreshold(){
        let ocr = OCR()
        let image = UIImage(named: "multiverse")
        self.measureBlock {
            ocr.cropScaleAndFilter(image)
        }
    }
    
    // MARK: OCR Perf
    func testPerformanceOCRMultiverse() {
        let ocr = OCR()
        let image = UIImage(named: "multiverse")
        self.measureBlock {
            ocr.process(image)
        }
    }
    
}


// MARK: TextMatcher
class TextMatcherTests: WYFISATests{
    
    func testMatchTextForGenPatterns(){
        let tm = TextMatcher()
        if let verseInfos = tm.findVersesInText("These are Genesis 1:1 verses, like Gcn 2:2 and Gen3:3 or Gen 4:4"){
            XCTAssert(verseInfos.count == 4)
            XCTAssert(verseInfos[0].name == "Genesis 1:1", verseInfos[0].name)
            XCTAssert(verseInfos[1].name == "Genesis 2:2", verseInfos[1].name)
            XCTAssert(verseInfos[2].name == "Genesis 3:3", verseInfos[2].name)
            XCTAssert(verseInfos[3].name == "Genesis 4:4", verseInfos[3].name)
        } else {
            XCTFail("expected match")
        }
        if let verseInfos = tm.findVersesInText("These are not linesis 1:1 verses, lake ocn2:2 and gen vin3:3 or G\new 4:4 iGalesis1:1"){
            XCTFail("unexpected match \(verseInfos[0].name)")
        }
    }
    
    
    func testMatchTextForExPatterns(){
        let tm = TextMatcher()
        if let verseInfos = tm.findVersesInText("These are Exodus 1:1 verses, like Ex 2:2"){
            XCTAssert(verseInfos.count == 2)
            XCTAssert(verseInfos[0].name == "Exodus 1:1", verseInfos[0].name)
            XCTAssert(verseInfos[1].name == "Exodus 2:2", verseInfos[1].name)
        } else {
            XCTFail("expected match")
        }
        if let verseInfos = tm.findVersesInText("These are not vsodus 1:1 verses, like avx2:2 and ex avarioun3:3 or GiX\new 4:4"){
            XCTFail("unexpected match \(verseInfos[0].name)")
        }
    }
    
    
    func testMatchTextForLevPatterns(){
        let tm = TextMatcher()
        if let verseInfos = tm.findVersesInText("These are Leviticus 1:1 verses, like Lev 2:2"){
            XCTAssert(verseInfos.count == 2)
            XCTAssert(verseInfos[0].name == "Leviticus 1:1", verseInfos[0].name)
            XCTAssert(verseInfos[1].name == "Leviticus 2:2", verseInfos[1].name)
        } else {
            XCTFail("expected match")
        }
        if let verseInfos = tm.findVersesInText("These are not Lemation 1:1 verses, like unleavened 2:2 and lavetics:3 "){
            XCTFail("unexpected match \(verseInfos[0].name)")
        }
    }
    
    func testMatchTextForNumPatterns(){
        let tm = TextMatcher()
        if let verseInfos = tm.findVersesInText("These are Numbers 1:1 verses, like Num 2:2"){
            XCTAssert(verseInfos.count == 2)
            XCTAssert(verseInfos[0].name == "Numbers 1:1", verseInfos[0].name)
            XCTAssert(verseInfos[1].name == "Numbers 2:2", verseInfos[1].name)
        } else {
            XCTFail("expected match")
        }
        if let verseInfos = tm.findVersesInText("These are not Nermbers 1:1 verses, like NoNumom 2:2 nev3:3 or Natahn"){
            XCTFail("unexpected match \(verseInfos[0].name)")
        }
    }
    
    func testMatchTextForDeutPatterns(){
        let tm = TextMatcher()
        if let verseInfos = tm.findVersesInText("These are Deuteronomy 1:1 verses, like Deut 2:2 With gouda Spell check like Dart 3:3 and Dunteros 4:4, but definitely not ever Rala1:1 or Cantel2:3"){
            XCTAssert(verseInfos.count == 3, "\(verseInfos.count)")
            XCTAssert(verseInfos[0].name == "Deuteronomy 1:1", verseInfos[0].name)
            XCTAssert(verseInfos[1].name == "Deuteronomy 2:2", verseInfos[1].name)
            XCTAssert(verseInfos[2].name == "Deuteronomy 3:3", verseInfos[2].name)
        } else {
            XCTFail("expected match")
        }
    }
    
    func testBookIdForPattern(){
        let tm = TextMatcher()
        let patterns = tm.bookPatterns()
        XCTAssert(patterns.length > 0)
        
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book != nil)
            // match on 2nd pattern
            let patternToMatch = tm.pattern(book!).componentsSeparatedByString("|")[0]
            let bookId = tm.patternId(patternToMatch)
            let gotBook = Books.init(rawValue: bookId)

            XCTAssert(book!.rawValue == bookId,
                      "Thought \(book!.name())\n\t\(tm.pattern(gotBook!)) \nwas \(gotBook!.name())\n\t\( tm.pattern(book!))")
        }
    }
    
    func testEveryBookHasPattern(){
        let tm = TextMatcher()
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book != nil)
            let pattern = tm.pattern(book!)
            let patternList = pattern.componentsSeparatedByString("|")
            if book == Books.Jude || book == Books.Philemon {
                XCTAssert(patternList.count == 1) // only 1 pattern
            } else {
                XCTAssert(patternList.count > 1) // at least 1 or more patterns per book
            }
        }
    }
    
    func testEveryPatternMatchesBook(){
        let tm = TextMatcher()
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book != nil)
            let pattern = tm.pattern(book!)
            let regex: Regex = Regex(pattern,  options: [])
            let matches = regex.allMatches(book!.name())
            XCTAssert(matches.count > 0)
            XCTAssert(matches[0].matchedString == book!.name())
        }
    }
    
    func testMatcherHasAllPatterns(){
        let tm = TextMatcher()
        let patterns = tm.bookPatterns()
        XCTAssert(patterns.length > 0)
        
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book != nil)
            
            // should be able to find each pattern
            XCTAssert(patterns.containsString(tm.pattern(book!)),
                      "missing pattern for \(book!.name())")
        }
    }
    
    
    func testMatchTextForJohn(){
        let tm = TextMatcher()
        if let verseInfos = tm.findVersesInText("There is only one way to life (See. John 14:6) for the answer"){
            XCTAssert(verseInfos.count == 1)
            XCTAssert(verseInfos[0].name == "John 14:6", verseInfos[0].name)
            XCTAssert(verseInfos[0].id == "43014006", verseInfos[0].id)
        } else {
            XCTFail("expected match")
        }
    }
    
    
    func testMatchTextForIsa(){
        let tm = TextMatcher()
        print(tm.pattern(Books.Isa))
        if let verseInfos = tm.findVersesInText("Behold a lamb (See. Isa: 53:7) was the answer"){
            XCTAssert(verseInfos.count == 1)
            XCTAssert(verseInfos[0].name == "Isaiah 53:7", verseInfos[0].name)
        } else {
            XCTFail("expected match")
        }
    }
 
    func testMatchTextForActs(){
        let tm = TextMatcher()
        print(tm.pattern(Books.Acts))
        if let verseInfos = tm.findVersesInText("pride (Acts 12:21-23)"){
            XCTAssert(verseInfos.count == 1)
            XCTAssert(verseInfos[0].name == "Acts 12:21", verseInfos[0].name)
        } else {
            XCTFail("expected match")
        }
    }
    func testNoMatchTextForPattern(){
        let tm = TextMatcher()
        print(tm.pattern(Books.Jn))
        if let _ = tm.findVersesInText("There is only one way to life (See. Jopv 14:6) for the answer"){
            XCTFail("unexpected match detected")
        }
    }

    

}

