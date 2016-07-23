//
//  TextMatcher.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import Regex


class VerseInfo {
    let id: String
    var name: String
    var text: String?
    var chapter: String?
    var refs: [VerseInfo]?
    
    init(id: String, name: String, text: String?){
        self.id = id
        self.name = name
        self.text = text
    }
}

class TextMatcher {
    
    class func findVersesInText(text: String) -> [VerseInfo]? {
        var verseInfos: [VerseInfo]?
        let bookStr = Books.bookPatterns()
        let chapters: Regex = Regex("(\(bookStr))\\w*?.?\\s?(\\d{1,3})(?:\\s|:|;)\\s?(\\d{1,3})",  options: [.IgnoreCase])

        // replace instances of 'l' and 'i' with 1
        let parsedText = text.replace("l", with: "1").replace("i", with: "1").replace("I", with: "1")
        let matches = chapters.allMatches(parsedText)
        for match in matches {
            let bookStr = match.captures[0]!
            let chapter = match.captures[1]!
            let verse = match.captures[2]!
            
            let bookId = Books.patternId(bookStr)
            let book = Books(rawValue: bookId)!.name()
            let matchedText = "\(book) \(chapter):\(verse)"

            let bookIdStr = String(format: "%02d", bookId)
            let chapterId = String(format: "%03d", Int(chapter)!)
            let verseId = String(format: "%03d", Int(verse)!)
            let id = "\(bookIdStr)\(chapterId)\(verseId)"
            let info = VerseInfo(id: id, name: matchedText, text: "Not Found")

            if verseInfos == nil {
                verseInfos = [VerseInfo]()
            }
            verseInfos!.append(info)
        }
        return verseInfos
    }
}