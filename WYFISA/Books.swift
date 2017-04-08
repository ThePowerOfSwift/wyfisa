//
//  Books.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

struct LexiconData {
    var greek: [[String:AnyObject]]
    var hebrew: [[String:AnyObject]]
    static let sharedInstance = LexiconData()

    init(){
        self.greek = [[String:AnyObject]]()
        self.hebrew = [[String:AnyObject]]()
        var filePath = NSBundle.mainBundle().pathForResource("greek",ofType:"json")
        if let jsonData = NSData.init(contentsOfFile: filePath!) {
            do {
                let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                self.greek = jsonDict as! [[String:AnyObject]]
            } catch  let err {
                print(err, "json load error")
            }
        }
        filePath = NSBundle.mainBundle().pathForResource("hebrew",ofType:"json")
        if let jsonData = NSData.init(contentsOfFile: filePath!) {
            do {
                let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                self.hebrew = jsonDict as! [[String:AnyObject]]
            } catch  let err {
                print(err, "json load error")
            }
        }
    }
    
    func getEntry(testament: String, strongs: String) -> LexiconEntry? {
        let array =  testament == "greek" ? greek : hebrew
        if let value = array.filter({($0["strongs"] as! String) == strongs}).first {
            
            let word = value["word"] as! String
            
            let data = value["data"] as! [String: AnyObject]
            let deriv = data["deriv"] as! String
            let def = data["def"] as! [String: AnyObject]
            let short = "\n"+(def["short"] as! String).firstCharacterUpperCase()
            var long = "\n"
            for longVal in def["long"] as! [AnyObject] {
                //long.append(longVal)
                if var longValStr = longVal as? String {
                    longValStr = longValStr.firstCharacterUpperCase()
                    long.appendContentsOf("\n- \(longValStr)")
                } else if let longValSubVal = longVal as? [String] {
                    var i = 0
                    for var longValSubStr in longValSubVal {
                        if i > 0 {
                            long.appendContentsOf(",")
                        }
                        longValSubStr = longValSubStr.firstCharacterUpperCase()
                        long.appendContentsOf(" (\(longValSubStr))")
                        i += 1
                    }
                }
            }
            
            let entry = LexiconEntry(strongs: strongs,
                                     word: word,
                                     deriv: deriv,
                                     shortDef: short,
                                     longDef: long)
            return entry
        }
        
        return nil
    }
}

struct BooksData {
    var data: [[String:AnyObject]]
    var stats: [String:[String:Int]]
    static let sharedInstance = BooksData()

    init(){
        self.data = [[String:AnyObject]]()
        self.stats = [String:[String:Int]]()
        var filePath = NSBundle.mainBundle().pathForResource("books",ofType:"json")
        if let jsonData = NSData.init(contentsOfFile: filePath!) {
            do {
                let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                self.data = jsonDict as! [[String:AnyObject]]
            } catch  let err {
                print(err, "json load error")
            }
            
        }
        filePath = NSBundle.mainBundle().pathForResource("stats",ofType:"json")
        if let jsonData = NSData.init(contentsOfFile: filePath!) {
            do {
                let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                self.stats = jsonDict as! [String:[String:Int]]
            } catch  let err {
                print(err, "json load error")
            }
            
        }
    }
    
    func numVerses(book: Int, chapter: Int) -> Int? {
        // check that book, chapter and verse are within range
        if self.exists(book, chapter: chapter, verse: 1) {
            return self.stats["\(book)"]!["\(chapter)"]!+1
        }
        return nil
    }
    
    func exists(book: Int, chapter: Int, verse: Int) -> Bool {
        
        // check that book, chapter and verse are within range
        let b = "\(book)"
        let c = "\(chapter)"
        if self.stats[b] != nil &&
            self.stats[b]![c] != nil
        {
            if verse <= self.stats[b]![c]! {
                return true
            }
        }
        
        return false
    }
}


enum Books: Int {
    
    case Gen = 1,Ex,Lev,Num,Deut,Josh,Judg,Ruth,Sam1,Sam2,Kings1,Kings2,Chr1,Chr2,Ezra,Neh,Esth,Job,Ps,Prov,Ecc,Song,Isa,Jer,Lam,Ezek,Dan,Hos,Joel,Am,Ob,Jon,Mic,Nah,Hab,Zeph,Hag,Zech,Mal,Mt,Mk,Lk,Jn,Acts,Rom,Cor1,Cor2,Gal,Eph,Phil,Col,Thess1,Thess2,Tim1,Tim2,Titus,Philemon,Heb,Jas,Pet1,Pet2,Jn1,Jn2,Jn3,Jude,Rev
    
    func name() -> String {
        let data = BooksData.sharedInstance.data
        let bookName = data[self.rawValue-1]["n"] as! String
        return bookName
    }
    
    func chapters() -> Int {
        let data = BooksData.sharedInstance.data
        let n = data[self.rawValue-1]["c"] as! Int
        return n
    }
}
