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
    
    // MARK: TextMatcher
    func testEveryBookHasPattern(){
        let tm = TextMatcher()
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book != nil)
            let pattern = tm.pattern(book!)
            let patternList = pattern.componentsSeparatedByString("|")
            XCTAssert(patternList.count > 1) // at least 1 or more patterns per book
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
    

    
    func testBookIdForPattern(){
        let tm = TextMatcher()
        let patterns = tm.bookPatterns()
        XCTAssert(patterns.length > 0)
        
        for i in 1...66 {
            let book = Books.init(rawValue: i)
            XCTAssert(book != nil)
            // match on 2nd pattern
            let patternToMatch = tm.pattern(book!).componentsSeparatedByString("|")[1]
            let bookId = tm.patternId(patternToMatch)
            XCTAssert(book!.rawValue == bookId,
                      "Got \(bookId), Expected \(book!.rawValue)")
        }
    }
    
    func testMatchTextForPattern(){
        let tm = TextMatcher()
        if let verseInfos = tm.findVersesInText("There is only one way to life (See. John 14:6) for the answer"){
            XCTAssert(verseInfos.count == 1)
            XCTAssert(verseInfos[0].name == "John 14:6", verseInfos[0].name)
        } else {
            XCTFail("expected match")
        }
    }
    
    func testNoMatchTextForPattern(){
        let tm = TextMatcher()
        if let _ = tm.findVersesInText("There is only one way to life (See. Jorn 14:6) for the answer"){
            XCTFail("unexpected match detected")
        }
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
