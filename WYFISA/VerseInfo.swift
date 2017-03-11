//
//  VerseInfo.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/28/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import Foundation
import Regex

enum ItemCategory: Int {
    case Verse = 0, Note, Image
}

class VerseInfo {
    let id: String
    var key: String
    var name: String
    var priority: Float = -1.0
    var session: UInt64 = 0
    var text: String?
    var chapter: String?
    var chapterNo: Int?
    var bookNo: Int?
    var verse: Int?
    var image: UIImage?
    var overlayImage: UIImage?
    var accessoryImage: UIImage?
    var refs: [VerseInfo]?
    var verses: [VerseInfo]?
    var category: ItemCategory = .Verse
    var ts: NSTimeInterval
    var createdAt: String
    var cellID: CellIdentifier? = nil
    var scriptId: String? = nil

    init(id: String, name: String, text: String?){
        self.id = id
        self.name = name
        self.text = text
        self.ts =  NSDate().timeIntervalSince1970
        self.createdAt = self.ts.description
        let seed = randomString(10)
        self.key = "\(self.createdAt)\(seed)"
        if self.category == .Verse {
            self.updateWithIdParts()
        }
    }
    
    func genKey(){
        let seed = randomString(10)
        self.key = "\(self.createdAt)\(seed)"
    }
    
    func toDocProperties() -> [String : AnyObject] {
        
        // optional values
        let text =  self.text ?? ""
        let chapter = self.chapter ?? ""
        let chapterNo = self.chapterNo ?? 0
        let bookNo = self.bookNo ?? 0
        let verse =  self.verse ?? 0
        let script = self.scriptId ?? ""

        // doc props
        let properties: [String : AnyObject] = ["id": self.id,
             "name": self.name,
             "priority": self.priority,
             "session": NSNumber(unsignedLongLong: self.session),
             "chapter": chapter,
             "chapterNo": chapterNo,
             "bookNo": bookNo,
             "verse": verse,
             "category": self.category.rawValue,
             "ts": self.ts,
             "text": text,
             "createdAt": self.createdAt,
             "script": script,
             "key": self.key,
        ]
        
        return properties
    }
    
    class func DocPropertiesToObj(doc: AnyObject?) -> VerseInfo? {
        
        var verseInfo:VerseInfo? = nil
        let dbq: DBQuery = DBQuery.sharedInstance

        if let verseDoc = doc as? [String: AnyObject] {
            let id = verseDoc["id"] as? String ?? ""
            let name = verseDoc["name"] as? String ?? ""
            
            // get text from db
            var text:String? =  verseDoc["text"] as? String ?? ""

            let v = VerseInfo.init(id: id, name: name, text: text)
   
            let categoryVal = verseDoc["category"] as? Int ?? 0
            if let category = ItemCategory(rawValue: categoryVal) {
                v.category = category
            }
            
            if let session = verseDoc["session"] as? NSNumber {
                v.session = session.unsignedLongLongValue
            }
            
            v.scriptId = verseDoc["script"] as? String ?? ""
            v.createdAt = verseDoc["createdAt"] as? String ?? ""
            v.priority = verseDoc["priority"] as? Float ?? -1
            v.chapter = verseDoc["chapter"] as? String ?? ""
            v.chapterNo = verseDoc["chapterNo"] as? Int ?? 0
            v.bookNo = verseDoc["bookNo"] as? Int ?? 0
            v.verse = verseDoc["verse"] as? Int ?? 0
            v.key = verseDoc["key"] as? String ?? ""
            v.updateWithIdParts()
            verseInfo = v
        }
        
        
        return verseInfo
    }
    
    func updateChapterForVerses(verses: [VerseInfo]){
        // TODO: don't redo
        
        var i = 1
        var chapterStr = ""
        
        for verse in verses {
            if var rc = verse.text {
                if (i == self.verse){ // this is context verse
                    if i == 1 {
                        rc = "\u{293}\(rc)\u{297}"
                    } else {
                        rc = "  \u{293}\(i) \(rc)\u{297}"
                    }
                } else {
                    if i == 1 {
                        rc = "\(rc)"
                    } else {
                        rc = "  \(i) \(rc)"
                    }
                }
                chapterStr = chapterStr.stringByAppendingString(rc)
            }
            i+=1
        }
        self.verses = verses
        self.chapter = chapterStr
    }
    
    func updateWithIdParts() {
        let pattern: Regex = Regex("(\\d{2})(\\d{3})(\\d{3})")
        let match = pattern.match(self.id)
        
        if let book = match?.captures[0] {
            self.bookNo = (Int(book)!)
        }
        if let chapter = match?.captures[1] {
            self.chapterNo = Int(chapter)!
        }
        if let verse = match?.captures[2] {
            self.verse = Int(verse)!
        }
    }

}
