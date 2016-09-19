//
//  WYFISAUITests.swift
//  WYFISAUITests
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import XCTest

class WYFISAUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    

    func testDidSearchForVerse(){
        
        let app = XCUIApplication()
        var verseSearchField = app.searchFields["verse"]
        verseSearchField.tap()
        app.searchFields["verse"].typeText("ep")
        let collectionViewsQuery2 = app.collectionViews
        let collectionViewsQuery = collectionViewsQuery2
        collectionViewsQuery.staticTexts["2"].tap()
        collectionViewsQuery.staticTexts["11"].tap()
        
        
        // another verse
        verseSearchField = app.searchFields["verse"]
        verseSearchField.tap()
        app.searchFields["verse"].typeText("jo")
        collectionViewsQuery2.childrenMatchingType(.Cell).elementBoundByIndex(4).staticTexts["3"].tap()
        collectionViewsQuery2.childrenMatchingType(.Cell).elementBoundByIndex(38).staticTexts["16"].tap()
        app.buttons["Oval 1"].pressForDuration(1.7);
        
    }
    
    func testSearchAfterCapture(){
        
        let app = XCUIApplication()
        let oval1Button = app.buttons["Oval 1"]
        oval1Button.pressForDuration(6.0)
        
        // expecting 5 labels with header
        let cells = app.cells
        let count = NSPredicate(format: "count == 6")
        expectationForPredicate(count, evaluatedWithObject: cells, handler: nil)
        waitForExpectationsWithTimeout(1, handler: nil)
        
        let verseSearchField = app.searchFields["verse"]
        verseSearchField.tap()
        app.searchFields["verse"].typeText("ep")
        
        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.staticTexts["2"].tap()
        collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(7).staticTexts["3"].tap()
        
        verseSearchField.tap()
        app.searchFields["verse"].typeText("jo")
        collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(4).staticTexts["3"].tap()
        collectionViewsQuery.childrenMatchingType(.Cell).elementBoundByIndex(38).staticTexts["16"].tap()
        oval1Button.pressForDuration(1.1);
        
    }
    
    func testDidCaptureVerses() {
        
        let app = XCUIApplication()
        let oval1Button = app.buttons["Oval 1"]
        oval1Button.pressForDuration(6.0)
        

        oval1Button.pressForDuration(6.0)
        
    }
    
}
