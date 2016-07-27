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
        let chapters: Regex = Regex("(\(bookStr))(?:\\D{0,2})(\\d{1,3})(?:\\D{1,2})(\\d{1,3})",  options: [.IgnoreCase])

        let matches = chapters.allMatches(text)
        for match in matches {
            
            let bookStr = match.captures[0]!
            print(bookStr)
            let chapter = match.captures[1]!
            let verse = match.captures[2]!
            let bookId = self.patternId(bookStr)
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
    
    func pattern(book: Books) -> String {
        let bookName = book.name()
        switch book {
        case .Gen:
            return bookName+"|G\\w{6}|G\\wn|\\wen|Ge\\w"
        case .Ex:
            return bookName+"|E\\w{5}|Ex\\w{0,2}"
        case .Lev:
            return bookName+"|L\\w{8}|L\\wv"
        case .Num:
            return bookName+"|N\\w{6}|Nu\\w|N\\wm|\\wum"
        case .Deut:
            return bookName+"|Deut|Dt "
        case .Josh:
            return bookName+"|Josh|Jos|Jsh"
        case .Judg:
            return bookName+"|Judg|Jdg|Jg |Jdgs"
        case .Ruth:
            return bookName+"|Rth"
        case .Sam1:
            return bookName+"|1 Samue1|1 Sam|1 Sa|1Samue1|1 Sa|1 Sm|1 Sam|1Sam|1 Samue1|1st Samue1|F1rst Samue1"
        case .Sam2:
            return bookName+"|2 Samue1|2 Sam|2 Sa|2S|11 Sa|2 Sm|11 Sam|2Sam|11 Samue1|2Samue1|2nd Samue1|Second Samue1"
        case .Kings1:
            return bookName+"|1 K1ngs|1 Kgs|1 K1|1K|1 Kgs|1Kgs|1 K1|1K1|1 K1ngs|1K1ngs|1st Kgs|1st K1ngs|F1rst K1ngs|F1rst Kgs|1K1n"
        case .Kings2:
            return bookName+"|2 K1ngs|2 Kgs|2 K1|2K|11 Kgs|2Kgs|11 K1|2K1|11 K1ngs|2K1ngs|2nd Kgs|2nd K1ngs|Second K1ngs|Second Kgs|2K1n"
        case .Chr1:
            return bookName+"|1 Chron1c1es|1 Chron|1 Ch|1 Ch|1Ch|1 Chr|1 Chr|1Chr|1 Chron|1Chron|1 Chron1c1es|1Chron1c1es|1st Chron1c1es|F1rst Chron1c1es"
        case .Chr2:
            return bookName+"|2 Chron1c1es|2 Chron|2 Ch|11 Ch|2Ch|11 Chr|2Chr|11 Chron|2Chron|11 Chron1c1es|2Chron1c1es|2nd Chron1c1es|Second Chron1c1es"
        case .Ezra:
            return bookName+"|Ezr"
        case .Neh:
            return bookName+"|Nehem1ah|Neh"
        case .Esth:
            return bookName+"|Esth"
        case .Job:
            return bookName+"|Jb"
        case .Ps:
            return bookName+"|Psa1m|Psa1m|Psa|Ps1m|Ps|Psa1ms|Psa|Psm|Pss|P5"
        case .Prov:
            return bookName+"|Prov|Pr|Prv"
        case .Ecc:
            return bookName+"|Ecc1es1astes|Ecc1es1astes|Ecc1es|Ecc|Ec|Qoh|Qohe1eth"
        case .Song:
            return bookName+"|Song|of So1omon Song|Cant1c1e of Cant1c1es|Cant1c1es|Song of Songs|SOS"
        case .Isa:
            return bookName+"|1sa1ah|1sa|1s"
        case .Jer:
            return bookName+"|Jerem1ah|Jer|Je|Jr"
        case .Lam:
            return bookName+"|Lamentat1ons|Lam|La"
        case .Ezek:
            return bookName+"|Ezek1e1|Ezek|Eze|Ezk"
        case .Dan:
            return bookName+"|Dan1e1|Dan|Da|Dn"
        case .Hos:
            return bookName+"|Hos|Ho"
        case .Joel:
            return bookName+"|Joe1|Joe1|Joe|J1"
        case .Am:
            return bookName+"|Am"
        case .Ob:
            return bookName+"|Obad1ah|Obad|Ob "
        case .Jon:
            return bookName+"|Jnh|Jon"
        case .Mic:
            return bookName+"|M1cah|M1c"
        case .Nah:
            return bookName+"|Nah|Na"
        case .Hab:
            return bookName+"|Hab"
        case .Zeph:
            return bookName+"|Zephan1ah|Zeph|Zep"
        case .Hag:
            return bookName+"|Hagga1|Hag"
        case .Zech:
            return bookName+"|Zechar1ah|Zech"
        case .Mal:
            return bookName+"|Ma1ach1|Ma1|Ma1"
        case .Mt:
            return bookName+"|Matt|Mt"
        case .Mk:
            return bookName+"|Mrk|Mk|Mr"
        case .Lk:
            return bookName+"|1uke|Luk|Lk"
        case .Jn:
            return bookName+"|John|Dohn|Jn|jn|Jhn|1n|1ohn"
        case .Acts:
            return bookName+"|Ac"
        case .Rom:
            return bookName+"|Rom|Ro|Rm|1om|1Romans"
        case .Cor1:
            return bookName+"|1 Cor1nth1ans|1 Cor|1 Cor|1Cor|1 Cor1nth1ans|1Cor1nth1ans|1st Cor1nth1ans|F1rst Cor1nth1ans"
        case .Cor2:
            return bookName+"|2 Cor1nth1ans|2 Cor|11 Cor|2Cor|11 Cor1nth1ans|2Cor1nth1ans|2nd Cor1nth1ans|Second Cor1nth1ans"
        case .Gal:
            return bookName+"|Ga1at1ans|Ga1|Ga"
        case .Eph:
            return bookName+"|Ephes1ans|Ephes|Eph"
        case .Phil:
            return bookName+"|Ph111pp1ans|Ph11|Php"
        case .Col:
            return bookName+"|Co1oss1ans|Co1"
        case .Thess1:
            return bookName+"|1 Thessa1on1ans|1 Thess|1 Th|1 Th|1Th|1 Thes|1Thes|1 Thess|1Thess|1 Thessa1on1ans|1Thessa1on1ans|1st Thessa1on1ans|F1rst Thessa1on1ans|1 T\\w{4}"
        case .Thess2:
            return bookName+"|2 Thessa1on1ans|2 Thess|2 Th|11 Th|2Th|11 Thes|2Thes|11 Thess|2Thess|11 Thessa1on1ans|2Thessa1on1ans|2nd Thessa1on1ans|Second Thessa1on1ans|2 T\\w{4}"
        case .Tim1:
            return bookName+"|1 T1mothy|1 T1m|1 T1|1 T1|1T1|1 T1m|1T1m|1 T1mothy|1T1mothy|1st T1mothy|F1rst T1mothy|1 T\\w{2}|1 T\\w{6}"
        case .Tim2:
            return bookName+"|2 T1mothy|2 T1m|2 T1|11 T1|2T1|11 T1m|2T1m|11 T1mothy|2T1mothy|2nd T1mothy|Second T1mothy|1 T\\w{2}|1 T\\w{6}"
        case .Titus:
            return bookName+"|T1tus|T1tus|T1t"
        case .Philemon:
            return bookName+"|Ph11emon|Ph11em|Phm"
        case .Heb:
            return bookName+"|Hebrews|Heb"
        case .Jas:
            return bookName+"|Jas|Jm"
        case .Pet1:
            return bookName+"|1 Pet|1 Pe|1 Pe|1Pe|1 Pet|1Pet|1 Pt|1 Pt|1Pt|1 Peter|1Peter|1st Peter|F1rst Peter|1 P\\w{2,4}"
        case .Pet2:
            return bookName+"|2 Pet|2 Pe|11 Pe|2Pe|11 Pet|2Pet|11 Pt|2 Pt|2Pt|11 Peter|2Peter|2nd Peter|Second Peter"
        case .Jn1:
            return bookName+"|1 1ohn|1 Jn|1 Jn|1Jn|1 Jo|1Jo|1 Joh|1Joh|1 Jhn|1 Jhn|1Jhn|1 John|1John|1st John|F1rst John"
        case .Jn2:
            return bookName+"|2 1ohn|2 Jn|11 Jn|2Jn|11 Jo|2Jo|11 Joh|2Joh|11 Jhn|2 Jhn|2Jhn|11 John|2John|2nd John|Second John"
        case .Jn3:
            return bookName+"|3 1ohn|3 Jn|111 Jn|3Jn|111 Jo|3Jo|111 Joh|3Joh|111 Jhn|3 Jhn|3Jhn|111 John|3John|3rd John|Th1rd John"
        case .Jude:
            return bookName+"|1ude|Jud"
        case .Rev:
            return bookName+"|Reve1at1on|Rev|Re|The Reve1at1on"
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
    // gives new testamant priority
    func bookPatterns() -> String {
        
        let matt = Books.Mt
        var books = self.pattern(matt)
        let ntStart = matt.rawValue+1
        for i in ntStart...66 {
            if let book = Books(rawValue: i) {
                books.appendContentsOf("|\(self.pattern(book))")
            }
        }
        for i in 1..<matt.rawValue {
            if let book = Books(rawValue: i) {
                books.appendContentsOf("|\(self.pattern(book))")
            }
        }
        return books
    }
}