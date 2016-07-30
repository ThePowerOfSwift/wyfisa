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
    
    
    func findVersesInText(text: String) -> [VerseInfo]? {
        
        var verseInfos: [VerseInfo]?
        let bookStr = self.bookPatterns()
        let chapters: Regex = Regex("\\W(\(bookStr))(?:\\D{0,2})(\\d{1,3})(?:\\D{1,2})(\\d{1,3})",  options: [.IgnoreCase])

        let matches = chapters.allMatches(text)
        for match in matches {
            
            let bookStr = match.captures[0]!
            let chapter = match.captures[1]!
            let verse = match.captures[2]!
            if startsWithZero(chapter) == true ||
                startsWithZero(verse) == true {
                continue // bogus
            }
            
            let bookId = self.patternId(bookStr)
            let book = Books(rawValue: bookId)!.name()
            let matchedText = "\(book) \(chapter):\(verse)"
            print(bookStr, matchedText)

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
    
    func startsWithZero(s: String) -> Bool {
        return s[s.startIndex.advancedBy(0)] == "0"
    }
    
    func isNumber(c: Character) -> Bool {
        switch c {
        case "1":
            return true
        case "2":
            return true
        case "3":
            return true
        default:
            return false
        }
    }
    func isVowel(c: Character) -> Bool {
        switch c {
            case "a":
                return true
            case "e":
                return true
            case "i":
                return true
            case "o":
                return true
            case "u":
                return true
            case "y":
                return true
        default:
            return false
        }
    }
    
    func allowsFirstTwoCharAbbr(name: String) -> Bool {
        switch name {
            case Books.Ex.name():
                return true
            case Books.Ps.name():
                return true
            case Books.Am.name():
                return true
        case Books.Isa.name():
                return true
        default:
            return false
        }
    }
    
    func allowsThreeLetterAbbr(name: String) -> Bool {
        switch name {
        case Books.Jude.name():
        return false
        case Books.Judg.name():
        return false
        default:
            return true
        }
    }
    
    func allowsLooseAbbr(name: String, ofSize: Int) -> Bool {
        // restrict loose abbreviation accross books
        // that could possibly conflict
        if ofSize == 3 {
            switch name {
            case Books.Nah.name():
                return false
            case Books.Neh.name():
                return false
            case Books.Heb.name():
                    return false
            case Books.Hab.name():
                return false
            case Books.Jude.name():
                return false
            case Books.Judg.name():
                return false
            case Books.Chr1.name():
                return false
            case Books.Chr2.name():
                return false
            case Books.Cor1.name():
                return false
            case Books.Cor2.name():
                return false
            case Books.Jon.name():
                return false
            default:
                return true
            }
        } else {
            switch name {
            case Books.Zech.name():
                return false
            case Books.Zeph.name():
                return false
            case Books.Am.name():
                 return false
            case Books.Acts.name():
                 return false
            case Books.Jude.name():
                return false
            case Books.Judg.name():
                return false
            default:
                return true
            }
        }
    }
    
    func allowsRangeAbbr(name: String) -> Bool {
        switch name {
        case Books.Zech.name():
            return false
        case Books.Zeph.name():
            return false
        default:
            return true
        }
    }
    
    func prefixMatches(pattern: String, c: Character) -> String {
        let matches = pattern.componentsSeparatedByString("|")
        
        switch c {
        case "1":
            var _p = matches[0]
            for i in 1...matches.count-1 {
                let m = "|1\\s{0,1}\(matches[i])|1st\\s{0,1}\(matches[i])|First\\s{0,1}\(matches[i])"
                _p = _p.stringByAppendingString(m)
            }
            return _p
        case "2":
            var _p = matches[0]
            for i in 1...matches.count-1 {
                let m = "|2\\s{0,1}\(matches[i])|2nd\\s{0,1}\(matches[i])|Second\\s{0,1}\(matches[i])"
                _p = _p.stringByAppendingString(m)
            }
            return _p
        case "3":
            var _p = matches[0]
            for i in 1...matches.count-1 {
                let m = "|3\\s{0,1}\(matches[i])|3rd\\s{0,1}\(matches[i])|Third\\s{0,1}\(matches[i])"
                _p = _p.stringByAppendingString(m)
            }
            return _p
        default:
            return pattern
        }
    }
    
    // creates a regex string for matching name
    func makeRegex(name: String) -> String{
        /* algorithm:
         *  1) 1st and last letter
         *  2) 1st and 2nd Char to end
         *  3) 1st and 3rd chars
         *  4) optionally: 1st and 4th chars
         */
        let n = name.length
        var cOffset = 0
        
        // get 1,2,3,4 chars
        let initChar = name[name.startIndex.advancedBy(cOffset)]
        if isNumber(initChar) == true {
            cOffset = 2
        }
        let firstChar = name[name.startIndex.advancedBy(cOffset)]
        let secondChar = name[name.startIndex.advancedBy(cOffset+1)]
        let thirdChar = name[name.startIndex.advancedBy(cOffset+2)]
        var fourthChar: Character? = nil
        let lastChar = name[name.endIndex.predecessor()]
        if n > 3 {
            fourthChar = name[name.startIndex.advancedBy(cOffset+3)]
        }

        var pattern = name
        
        if allowsRangeAbbr(name) == true {
            // ie Genesis, G.....s
            let match = "|\(firstChar)\\w{\(n-2)}\(lastChar)\\W"
            pattern = pattern.stringByAppendingString(match)
        }

        if allowsFirstTwoCharAbbr(name){
            // ie Exodus, Ex
            let match = "|\(firstChar)\(secondChar)\\W"
            pattern = pattern.stringByAppendingString(match)
        }
        
        // permutations of 3 letter abbrv
        if (isVowel(thirdChar) == false && allowsThreeLetterAbbr(name) == true)
            || name == Books.Isa.name() { // Isa the exception!
            // ie Genesis, Gn, G.n
            if allowsLooseAbbr(name, ofSize: 3) == true {
                let match = "|\(firstChar)\\w{0,1}\(thirdChar)"
                pattern = pattern.stringByAppendingString(match)
            } else {
                let match = "|\(firstChar)\(secondChar)\(thirdChar)"
                pattern = pattern.stringByAppendingString(match)
            }
        }



        if let c = fourthChar {
            if isVowel(c) == false && c != "l" { // no 4 letter abbr end in 'l'
                
                // ie... Deuteronomy, D..t, Dt
                if allowsLooseAbbr(name, ofSize: 4) == true {
                    let match = "|\(firstChar)\\w{2}\(c)"
                    pattern = pattern.stringByAppendingString(match)
                } else {
                    let match = "|\(firstChar)\(secondChar)\(thirdChar)\(c)"
                    pattern = pattern.stringByAppendingString(match)
                }
                let match = "|\(firstChar)\(c)"
                pattern = pattern.stringByAppendingString(match)
            }
        }
        if (cOffset > 0 ){
            pattern = prefixMatches(pattern, c: initChar)
        }
        return pattern

    }
    
    func pattern(book: Books) -> String {
        let bookName = book.name()
        return makeRegex(bookName)
    }
    
    // gets id of book for the given sub-pattern... ie Rom, or Rev
    func patternId(pattern: String) -> Int {
        for i in 1...66 {
            if let book = Books(rawValue: i) {
                let bookPatterns = self.pattern(book).componentsSeparatedByString("|")
                for matchPattern in bookPatterns {
                    let rx: Regex = Regex("^\(matchPattern)", options: [.IgnoreCase])
                    
                    let matches = rx.allMatches(pattern)
                    if matches.count > 0 {
                        return i
                    }
                }
            }
        }
        return 1
    }
    
    
    // get concatenated list of all book patterns
    func bookPatterns() -> String {
        var books = self.pattern(Books.Gen)
        for i in 2...66 {
            if let book = Books(rawValue: i) {
                books.appendContentsOf("|\(self.pattern(book))")
            }
        }
        return books
    }
}
