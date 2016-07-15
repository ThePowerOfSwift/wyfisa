//
//  TextMatcher.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/13/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import Regex


struct VerseInfo {
    let id: String
    var name: String
    var text: String?
}

class TextMatcher {
    
    class func findVersesInText(text: String) -> [VerseInfo]? {
        var verseInfos: [VerseInfo]?
        let bookStr = Books.bookPatterns()
        let chapters: Regex = Regex("(\(bookStr))\\w*?.? (\\d{1,3}):(\\d{1,3})",  options: [.IgnoreCase])
        
        let matches = chapters.allMatches(text)
        for match in matches {
            let book = match.captures[0]!
            let chapter = match.captures[1]!
            let verse = match.captures[2]!
            let matchedText = "\(book) \(chapter):\(verse)"
            
            let bookId = String(format: "%02d", Int(Books.patternId(book)))
            let chapterId = String(format: "%03d", Int(chapter)!)
            let verseId = String(format: "%03d", Int(verse)!)
            let id = "\(bookId)\(chapterId)\(verseId)" 
            let info = VerseInfo(id: id, name: matchedText, text: "Not Found")
            if verseInfos == nil {
                verseInfos = [VerseInfo]()
            }
            verseInfos!.append(info)
        }
        return verseInfos
    }
}

enum Books: Int {
    case Gen = 1,Ex,Lev,Num,Deut,Josh,Judg,Ruth,Sam1,Sam2,Kings1,Kings2,Chr1,Chr2,Ezra,Neh,Esth,Job,Ps,Prov,Ecc,Song,Isa,Jer,Lam,Ezek,Dan,Hos,Joel,Am,Ob,Jon,Mic,Nah,Hab,Zeph,Hag,Zech,Mal,Mt,Mk,Lk,Jn,Acts,Rom,Cor1,Cor2,Gal,Eph,Phil,Col,Thess1,Thess2,Tim1,Tim2,Titus,Philemon,Heb,Jas,Pet1,Pet2,Jn1,Jn2,Jn3,Jude,Rev
    func pattern() -> String {
        switch self {
        case .Gen:
            return "Genesis|Gen|Ge|Gn|Gcn"
        case .Ex:
            return "Exodus|Exo|Ex|Exod"
        case .Lev:
            return "Leviticus|Lev|Le|Lv"
        case .Num:
            return "Numbers|Num|Nu|Nm|Nb"
        case .Deut:
            return "Deuteronomy|Deut|Dt"
        case .Josh:
            return "Joshua|Josh|Jos|Jsh"
        case .Judg:
            return "Judges|Judg|Jdg|Jg|Jdgs"
        case .Ruth:
            return "Ruth|Rth|Ru"
        case .Sam1:
            return "1 Samuel|1 Sam|1 Sa|1Samuel|1S|I Sa|1 Sm|1Sa|I Sam|1Sam|I Samuel|1st Samuel|First Samuel"
        case .Sam2:
            return "2 Samuel|2 Sam|2 Sa|2S|II Sa|2 Sm|2Sa|II Sam|2Sam|II Samuel|2Samuel|2nd Samuel|Second Samuel"
        case .Kings1:
            return "1 Kings|1 Kgs|1 Ki|1K|I Kgs|1Kgs|I Ki|1Ki|I Kings|1Kings|1st Kgs|1st Kings|First Kings|First Kgs|1Kin"
        case .Kings2:
            return "2 Kings|2 Kgs|2 Ki|2K|II Kgs|2Kgs|II Ki|2Ki|II Kings|2Kings|2nd Kgs|2nd Kings|Second Kings|Second Kgs|2Kin"
        case .Chr1:
            return "1 Chronicles|1 Chron|1 Ch|I Ch|1Ch|1 Chr|I Chr|1Chr|I Chron|1Chron|I Chronicles|1Chronicles|1st Chronicles|First Chronicles"
        case .Chr2:
            return "2 Chronicles|2 Chron|2 Ch|II Ch|2Ch|II Chr|2Chr|II Chron|2Chron|II Chronicles|2Chronicles|2nd Chronicles|Second Chronicles"
        case .Ezra:
            return "Ezra|Ezra|Ezr"
        case .Neh:
            return "Nehemiah|Neh|Ne"
        case .Esth:
            return "Esther|Esth|Es"
        case .Job:
            return "Job|Jb"
        case .Ps:
            return "Psalm|Psa|Pslm|Ps|Psalms|Psa|Psm|Pss|P5"
        case .Prov:
            return "Proverbs|Prov|Pr|Prv"
        case .Ecc:
            return "Ecclesiastes|Eccles|Ecc|Ec|Qoh|Qoheleth"
        case .Song:
            return "Song|of Solomon Song|So|Canticle of Canticles|Canticles|Song of Songs|SOS"
        case .Isa:
            return "Isaiah|Isa|Is"
        case .Jer:
            return "Jeremiah|Jer|Je|Jr"
        case .Lam:
            return "Lamentations|Lam|La"
        case .Ezek:
            return "Ezekiel|Ezek|Eze|Ezk"
        case .Dan:
            return "Daniel|Dan|Da|Dn"
        case .Hos:
            return "Hosea|Hos|Ho"
        case .Joel:
            return "Joel|Joel|Joe|Jl"
        case .Am:
            return "Amos|Amos|Am"
        case .Ob:
            return "Obadiah|Obad|Ob"
        case .Jon:
            return "Jonah|Jnh|Jon"
        case .Mic:
            return "Micah|Mic"
        case .Nah:
            return "Nahum|Nah|Na"
        case .Hab:
            return "Habakkuk|Hab"
        case .Zeph:
            return "Zephaniah|Zeph|Zep|Zp"
        case .Hag:
            return "Haggai|Haggai|Hag|Hg"
        case .Zech:
            return "Zechariah|Zech|Zec|Zc"
        case .Mal:
            return "Malachi|Mal|Mal|Ml"
        case .Mt:
            return "Matthew|Matt|Mt"
        case .Mk:
            return "Mark|Mrk|Mk|Mr"
        case .Lk:
            return "Luke|Luk|Lk"
        case .Jn:
            return "John|John|Jn|Jhn"
        case .Acts:
            return "Acts|Acts|Ac"
        case .Rom:
            return "Romans|Rom|Ro|Rm"
        case .Cor1:
            return "1 Corinthians|1 Cor|1 Co|I Co|1Co|I Cor|1Cor|I Corinthians|1Corinthians|1st Corinthians|First Corinthians"
        case .Cor2:
            return "2 Corinthians|2 Cor|2 Co|II Co|2Co|II Cor|2Cor|II Corinthians|2Corinthians|2nd Corinthians|Second Corinthians"
        case .Gal:
            return "Galatians|Gal|Ga"
        case .Eph:
            return "Ephesians|Ephes|Eph"
        case .Phil:
            return "Philippians|Phil|Php"
        case .Col:
            return "Colossians|Col"
        case .Thess1:
            return "1 Thessalonians|1 Thess|1 Th|I Th|1Th|I Thes|1Thes|I Thess|1Thess|I Thessalonians|1Thessalonians|1st Thessalonians|First Thessalonians"
        case .Thess2:
            return "2 Thessalonians|2 Thess|2 Th|II Th|2Th|II Thes|2Thes|II Thess|2Thess|II Thessalonians|2Thessalonians|2nd Thessalonians|Second Thessalonians"
        case .Tim1:
            return "1 Timothy|1 Tim|1 Ti|I Ti|1Ti|I Tim|1Tim|I Timothy|1Timothy|1st Timothy|First Timothy"
        case .Tim2:
            return "2 Timothy|2 Tim|2 Ti|II Ti|2Ti|II Tim|2Tim|II Timothy|2Timothy|2nd Timothy|Second Timothy"
        case .Titus:
            return "Titus|Titus|Tit"
        case .Philemon:
            return "Philemon|Philem|Phm"
        case .Heb:
            return "Hebrews|Hebrews|Heb"
        case .Jas:
            return "James|James|Jas|Jm"
        case .Pet1:
            return "1 Peter|1 Pet|1 Pe|I Pe|1Pe|I Pet|1Pet|I Pt|1 Pt|1Pt|I Peter|1Peter|1st Peter|First Peter"
        case .Pet2:
            return "2 Peter|2 Pet|2 Pe|II Pe|2Pe|II Pet|2Pet|II Pt|2 Pt|2Pt|II Peter|2Peter|2nd Peter|Second Peter"
        case .Jn1:
            return "1 John|1 Jn|I Jn|1Jn|I Jo|1Jo|I Joh|1Joh|I Jhn|1 Jhn|1Jhn|I John|1John|1st John|First John"
        case .Jn2:
            return "2 John|2 Jn|II Jn|2Jn|II Jo|2Jo|II Joh|2Joh|II Jhn|2 Jhn|2Jhn|II John|2John|2nd John|Second John"
        case .Jn3:
            return "3 John|3 Jn|III Jn|3Jn|III Jo|3Jo|III Joh|3Joh|III Jhn|3 Jhn|3Jhn|III John|3John|3rd John|Third John"
        case .Jude:
            return "Jude|Jude|Jud"
        case .Rev:
            return "Revelation|Rev|Re|The Revelation"
        }
    }

    static func patternId(pattern: String) -> Int {
        for i in 1...66 {
            if let book = Books(rawValue: i) {
                let lfString = pattern+"|"
                let rtString = "|"+pattern
                if book.pattern().containsString(lfString) ||
                    book.pattern().containsString(rtString) {
                    return i
                }
            }
        }
        return 1
    }

    static func bookPatterns() -> String {
        var books = Books.Gen.pattern()
        for i in 2...66 {
            if let book = Books(rawValue: i) {
                books.appendContentsOf("|\(book.pattern())")
            }
        }
        return books
    }
}