//
//  WYFISATests.swift
//  WYFISATests
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import XCTest
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
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
