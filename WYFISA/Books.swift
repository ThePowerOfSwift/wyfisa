//
//  Books.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

struct BooksData {
    var data: [[String:AnyObject]]
    static let sharedInstance = BooksData()

    init(){
        self.data = [[String:AnyObject]]()
        let filePath = NSBundle.mainBundle().pathForResource("books",ofType:"json")
        if let jsonData = NSData.init(contentsOfFile: filePath!) {
            do {
                let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                self.data = jsonDict as! [[String:AnyObject]]
            } catch  let err {
                print(err, "json load error")
            }
            
        }
    }
}


enum Books: Int {
    
    case Gen = 1,Ex,Lev,Num,Deut,Josh,Judg,Ruth,Sam1,Sam2,Kings1,Kings2,Chr1,Chr2,Ezra,Neh,Esth,Job,Ps,Prov,Ecc,Song,Isa,Jer,Lam,Ezek,Dan,Hos,Joel,Am,Ob,Jon,Mic,Nah,Hab,Zeph,Hag,Zech,Mal,Mt,Mk,Lk,Jn,Acts,Rom,Cor1,Cor2,Gal,Eph,Phil,Col,Thess1,Thess2,Tim1,Tim2,Titus,Philemon,Heb,Jas,Pet1,Pet2,Jn1,Jn2,Jn3,Jude,Rev
    
    func name() -> String {
        let data = BooksData.sharedInstance.data
        let bookName = data[self.rawValue-1]["n"] as! String
        return bookName
    }
    
    func pattern() -> String {
        switch self {
        case .Gen:
            return "Genes1s|Gen|Ge|Gn|Gcn"
        case .Ex:
            return "Exodus|Exo|Ex|Exod"
        case .Lev:
            return "Lev1t1cus|Lev|Le|Lv"
        case .Num:
            return "Numbers|Num|Nu|Nm|Nb"
        case .Deut:
            return "Deuteronomy|Deut|Dt"
        case .Josh:
            return "Joshua|Josh|Jos|Jsh"
        case .Judg:
            return "Judges|Judg|Jdg|Jg|Jdgs"
        case .Ruth:
            return "Ruth|Rth"
        case .Sam1:
            return "1 Samue1|1 Sam|1 Sa|1Samue1|1 Sa|1 Sm|1 Sam|1Sam|1 Samue1|1st Samue1|F1rst Samue1"
        case .Sam2:
            return "2 Samue1|2 Sam|2 Sa|2S|11 Sa|2 Sm|11 Sam|2Sam|11 Samue1|2Samue1|2nd Samue1|Second Samue1"
        case .Kings1:
            return "1 K1ngs|1 Kgs|1 K1|1K|1 Kgs|1Kgs|1 K1|1K1|1 K1ngs|1K1ngs|1st Kgs|1st K1ngs|F1rst K1ngs|F1rst Kgs|1K1n"
        case .Kings2:
            return "2 K1ngs|2 Kgs|2 K1|2K|11 Kgs|2Kgs|11 K1|2K1|11 K1ngs|2K1ngs|2nd Kgs|2nd K1ngs|Second K1ngs|Second Kgs|2K1n"
        case .Chr1:
            return "1 Chron1c1es|1 Chron|1 Ch|1 Ch|1Ch|1 Chr|1 Chr|1Chr|1 Chron|1Chron|1 Chron1c1es|1Chron1c1es|1st Chron1c1es|F1rst Chron1c1es"
        case .Chr2:
            return "2 Chron1c1es|2 Chron|2 Ch|11 Ch|2Ch|11 Chr|2Chr|11 Chron|2Chron|11 Chron1c1es|2Chron1c1es|2nd Chron1c1es|Second Chron1c1es"
        case .Ezra:
            return "Ezra|Ezra|Ezr"
        case .Neh:
            return "Nehem1ah|Neh"
        case .Esth:
            return "Esther|Esth"
        case .Job:
            return "Job|Jb"
        case .Ps:
            return "Psa1m|Psa1m|Psa|Ps1m|Ps|Psa1ms|Psa|Psm|Pss|P5"
        case .Prov:
            return "Proverbs|Prov|Pr|Prv"
        case .Ecc:
            return "Ecc1es1astes|Ecc1es1astes|Ecc1es|Ecc|Ec|Qoh|Qohe1eth"
        case .Song:
            return "Song|of So1omon Song|So|Cant1c1e of Cant1c1es|Cant1c1es|Song of Songs|SOS"
        case .Isa:
            return "1sa1ah|1sa|1s"
        case .Jer:
            return "Jerem1ah|Jer|Je|Jr"
        case .Lam:
            return "Lamentat1ons|Lam|La"
        case .Ezek:
            return "Ezek1e1|Ezek|Eze|Ezk"
        case .Dan:
            return "Dan1e1|Dan|Da|Dn"
        case .Hos:
            return "Hosea|Hos|Ho"
        case .Joel:
            return "Joe1|Joe1|Joe|J1"
        case .Am:
            return "Amos|Amos|Am"
        case .Ob:
            return "Obad1ah|Obad|Ob"
        case .Jon:
            return "Jonah|Jnh|Jon"
        case .Mic:
            return "M1cah|M1c"
        case .Nah:
            return "Nahum|Nah|Na"
        case .Hab:
            return "Habakkuk|Hab"
        case .Zeph:
            return "Zephan1ah|Zeph|Zep|Zp"
        case .Hag:
            return "Hagga1|Hagga1|Hag|Hg"
        case .Zech:
            return "Zechar1ah|Zech|Zec|Zc"
        case .Mal:
            return "Ma1ach1|Ma1|Ma1|M1"
        case .Mt:
            return "Matthew|Matt|Mt"
        case .Mk:
            return "Mark|Mrk|Mk|Mr"
        case .Lk:
            return "Luke|Luk|Lk"
        case .Jn:
            return "John|John|Jn|jn|Jhn|1n|1ohn"
        case .Acts:
            return "Acts|Acts|Ac"
        case .Rom:
            return "Romans|Rom|Ro|Rm|1om|1Romans"
        case .Cor1:
            return "1 Cor1nth1ans|1 Cor|1 Co|1 Co|1Co|1 Cor|1Cor|1 Cor1nth1ans|1Cor1nth1ans|1st Cor1nth1ans|F1rst Cor1nth1ans"
        case .Cor2:
            return "2 Cor1nth1ans|2 Cor|2 Co|11 Co|2Co|11 Cor|2Cor|11 Cor1nth1ans|2Cor1nth1ans|2nd Cor1nth1ans|Second Cor1nth1ans"
        case .Gal:
            return "Ga1at1ans|Ga1|Ga"
        case .Eph:
            return "Ephes1ans|Ephes|Eph"
        case .Phil:
            return "Ph111pp1ans|Ph11|Php"
        case .Col:
            return "Co1oss1ans|Co1"
        case .Thess1:
            return "1 Thessa1on1ans|1 Thess|1 Th|1 Th|1Th|1 Thes|1Thes|1 Thess|1Thess|1 Thessa1on1ans|1Thessa1on1ans|1st Thessa1on1ans|F1rst Thessa1on1ans"
        case .Thess2:
            return "2 Thessa1on1ans|2 Thess|2 Th|11 Th|2Th|11 Thes|2Thes|11 Thess|2Thess|11 Thessa1on1ans|2Thessa1on1ans|2nd Thessa1on1ans|Second Thessa1on1ans"
        case .Tim1:
            return "1 T1mothy|1 T1m|1 T1|1 T1|1T1|1 T1m|1T1m|1 T1mothy|1T1mothy|1st T1mothy|F1rst T1mothy"
        case .Tim2:
            return "2 T1mothy|2 T1m|2 T1|11 T1|2T1|11 T1m|2T1m|11 T1mothy|2T1mothy|2nd T1mothy|Second T1mothy"
        case .Titus:
            return "T1tus|T1tus|T1t"
        case .Philemon:
            return "Ph11emon|Ph11em|Phm"
        case .Heb:
            return "Hebrews|Hebrews|Heb"
        case .Jas:
            return "James|James|Jas|Jm"
        case .Pet1:
            return "1 Peter|1 Pet|1 Pe|1 Pe|1Pe|1 Pet|1Pet|1 Pt|1 Pt|1Pt|1 Peter|1Peter|1st Peter|F1rst Peter"
        case .Pet2:
            return "2 Peter|2 Pet|2 Pe|11 Pe|2Pe|11 Pet|2Pet|11 Pt|2 Pt|2Pt|11 Peter|2Peter|2nd Peter|Second Peter"
        case .Jn1:
            return "1 John|1 Jn|1 Jn|1Jn|1 Jo|1Jo|1 Joh|1Joh|1 Jhn|1 Jhn|1Jhn|1 John|1John|1st John|F1rst John"
        case .Jn2:
            return "2 John|2 Jn|11 Jn|2Jn|11 Jo|2Jo|11 Joh|2Joh|11 Jhn|2 Jhn|2Jhn|11 John|2John|2nd John|Second John"
        case .Jn3:
            return "3 John|3 Jn|111 Jn|3Jn|111 Jo|3Jo|111 Joh|3Joh|111 Jhn|3 Jhn|3Jhn|111 John|3John|3rd John|Th1rd John"
        case .Jude:
            return "Jude|Jude|Jud"
        case .Rev:
            return "Reve1at1on|Rev|Re|The Reve1at1on"
        }
    }
    
    // gets id of book for the given pattern
    static func patternId(pattern: String) -> Int {
        for i in 1...66 {
            if let book = Books(rawValue: i) {
                let patterns = book.pattern().componentsSeparatedByString("|")
                for p in patterns {
                    if pattern.uppercaseString == p.uppercaseString {
                        return i
                    }
                }
            }
        }
        return 1
    }
    
    
    // get concatenated list of all book patterns
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
