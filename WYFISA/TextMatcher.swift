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
    var priority: Float = -1.0
    var session: UInt64 = 0
    var text: String?
    var chapter: String?
    var verse: Int?
    var image: UIImage?
    var refs: [VerseInfo]?
    var verses: [VerseInfo]?

    init(id: String, name: String, text: String?){
        self.id = id
        self.name = name
        self.text = text
    }
}

class TextMatcher {
    
    func findBookInText(text: String) -> Books? {
        
        var match: Books?

        // create a regex to match book pattern
        let bookRegex: Regex = Regex("(\\d\\s)?\\w+",  options: [.IgnoreCase])
        if let result = bookRegex.match(text){
            let bookText = result.matchedString
        
            // loop through books to find one that matches book pattern
            for i in 1...66 {
                var v = i + 39 // NT start
                if v > 66 {
                    v -= 66
                }
                if let book = Books(rawValue: v) {
                    let matchRegex = Regex("^\(bookText)",  options: [.IgnoreCase])
                    if matchRegex.matches(book.name()){
                        match = book
                        break
                    }
                }
            }
        }
        return match
    }
    
    func findChapterInText(text:String) -> String? {
        var match: String?
        let chapters: Regex = Regex("\\w+\\s+(\\d{1,3}):?",  options: [.IgnoreCase])
        let matches = chapters.allMatches(text)
        if matches.count > 0 {
            if let m = matches[0].captures[0] {
                match = m
            }
        }
        return match
    }
    
    func findVersesInText(text: String) -> [VerseInfo]? {
        
        var verseInfos: [VerseInfo]?
        let bookStr = self.bookPatterns()
        let chapters: Regex = Regex("(?:\\W|^)(\(bookStr))(?:\\D{0,2})(\\d{1,3})(?:\\D{1,2})(\\d{1,3})",  options: [.IgnoreCase])
        let textUpdate = text.replace("\n", with: "99") // prevent linebreak matches
        var textPriority = text.replace("\n", with: "^^") // newline detection

        let matches = chapters.allMatches(textUpdate)
        var priority: Float = 0.0
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
            let bookIdStr = String(format: "%02d", bookId)
            let chapterId = String(format: "%03d", Int(chapter)!)
            let verseId = String(format: "%03d", Int(verse)!)
            let id = "\(bookIdStr)\(chapterId)\(verseId)"
            let info = VerseInfo(id: id, name: matchedText, text: "Not Found")
            info.verse = Int(verse)
    
            if verseInfos == nil {
                verseInfos = [VerseInfo]()
            }
            // set priority based on line verse occurs
            let charsToBookStr: Regex = Regex("(.*)\(bookStr)",  options: [])
            let charMatches = charsToBookStr.allMatches(textPriority)
            if charMatches.count > 0 {
                let lMatch = charMatches[0].captures[0]!
                textPriority = textPriority.strip(lMatch)
                if lMatch.indexOfCharacter("^") != nil {
                    // new line detected, increase the priority
                    priority += 1.0
                } else {
                    // match was on same line
                    priority += 0.001
                }
            }
            
            if priority == 0 {
                priority = 1
            }
            info.priority = priority
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
            case Books.Ps.name():
                return false
            default:
                return true
            }
        }
    }
    
    func allowsRangeAbbr(name: String) -> Bool {
        let lastChar = name[name.endIndex.predecessor()]
        if lastChar == "s" || isVowel(lastChar) == true {
            return false
        }
        switch name {
        case Books.Zech.name():
            return false
        case Books.Zeph.name():
            return false
        default:
            return true
        }
    }
    
    func allowsRightRangeMatching(name: String) -> Bool {
        
        // rRange is often suspectible to dupes
        switch name {
        case Books.Zech.name():
            return false
        case Books.Zeph.name():
            return false
        case Books.Jer.name():
            return false
        case Books.Neh.name():
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
                let m = "|[1l]\\s{0,1}\(matches[i])|[1l]st\\s{0,1}\(matches[i])|First\\s{0,1}\(matches[i])"
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
            var match = "|\(firstChar)\\w{\(n-2-cOffset)}\(lastChar)\\W"
            pattern = pattern.stringByAppendingString(match)
            
            if lastChar == "y" { // often y becomes v
                match = "|\(firstChar)\\w{\(n-2-cOffset)}v\\W"
                pattern = pattern.stringByAppendingString(match)
            }
        }
        
        if (n-cOffset) > 5 { // better gap matching on big words
            let lRange = name[name.startIndex.advancedBy(cOffset)...name.startIndex.advancedBy(cOffset+4)]
            let rRange = name[name.startIndex.advancedBy(n-5)...name.startIndex.advancedBy(n-1)]
            let lmatch = "|\(lRange)\\w{0,\(n-5)}\\W"
            let rmatch = "|\\w{0,\(n-5)}\(rRange)\\W"
            pattern = pattern.stringByAppendingString(lmatch)
            if allowsRightRangeMatching(name){
                pattern = pattern.stringByAppendingString(rmatch)
            }
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
            if isVowel(c) == false { // no 4 letter abbr end in 'l'
                
                // ie... Deuteronomy, D..t, Dt
                if allowsLooseAbbr(name, ofSize: 4) == true {
                    let match = "|\(firstChar)\\w{2}\(c)"
                    pattern = pattern.stringByAppendingString(match)
                } else {
                    let match = "|\(firstChar)\(secondChar)\(thirdChar)\(c)"
                    pattern = pattern.stringByAppendingString(match)
                }
                
                if !(n == 4 && allowsRangeAbbr(name) == false){
                    // ie.. Dt
                    // avoid 4 letter books that cannot be abbr like 'acts' 'amos'
                    let match = "|\(firstChar)\(c)"
                    pattern = pattern.stringByAppendingString(match)
                }
            }
        }
        
        // TODO: learn fuzzy char replacements, ie
        // pattern = pattern.replace("l", with: "[1l]")
        
        if (cOffset > 0 ){
            pattern = prefixMatches(pattern, c: initChar)
        }
        return pattern

    }
    
    func pattern(book: Books) -> String {
        
        let bookName = book.name()
        
        // in general makeRegex will provide sufficient pattern
        // to match book. 'switch' here on special cases
        switch book {
        case .Jude:
            return bookName
        case .Philemon:
            return "\(bookName)|P\\w{5}n"
        case .Phil:
            return bookName+"|Phil\\W"
        case .Mt:
            let rx = makeRegex(bookName)
            return "\(rx)|Ma\\w{4,5}v"  // when w becomes 'v'
        default:
            return makeRegex(bookName)
        }
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


