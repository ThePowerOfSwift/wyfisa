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

var CHAPTER_CACHE = [String: [VerseInfo]]()

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
    var imageCropped: UIImage?
    var overlayImage: UIImage?
    var imageCroppedOffset: CGFloat = -1.0
    var isHighlighted: Bool = true
    var refs: [VerseInfo]?
    var verses: [VerseInfo]?
    var category: ItemCategory = .Verse
    var ts: NSTimeInterval
    var createdAt: String
    var cellID: CellIdentifier? = nil
    var scriptId: String? = nil
    var version: String = Version.KJV.text()
    var type = "verse"

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
             "version": SettingsManager.sharedInstance.version.text(),
             "cropOffset": self.imageCroppedOffset,
             "highlighted": self.isHighlighted,
             "script": script,
             "type": self.type,
             "key": self.key,
        ]
        
        return properties
    }
    
    class func DocPropertiesToObj(doc: AnyObject?) -> VerseInfo? {
        
        var verseInfo:VerseInfo? = nil

        if let verseDoc = doc as? [String: AnyObject] {
            let id = verseDoc["id"] as? String ?? ""
            let name = verseDoc["name"] as? String ?? ""
            let version = verseDoc["version"] as? String ?? Version.KJV.text()

            // get text from db
            let text:String? =  verseDoc["text"] as? String ?? ""

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
            v.imageCroppedOffset = verseDoc["cropOffset"] as? CGFloat ?? -1.0
            v.isHighlighted = verseDoc["highlighted"] as? Bool ?? true
            v.key = verseDoc["key"] as? String ?? ""
            v.version = version
            v.updateWithIdParts()
            verseInfo = v
        }
        
        
        return verseInfo
    }
    
    func updateChapterForVerses(verses: [VerseInfo]){
        // TODO: cache this... and ie the cache db is deleted on app reset
        
        var i = 1
        var chapterStr = ""
        var chapterVerses = [VerseInfo]()
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
                let chapterVerse = self.makeChapterVerse(i, verseText: verse.text)
                chapterVerses.append(chapterVerse)
            }
            i+=1
        }
        self.verses = chapterVerses
        self.chapter = chapterStr
        self.cacheVerses()
    }
    
    func cacheVerses(){
        if CHAPTER_CACHE.count > CHAPTER_CACHE_MAX {
            CHAPTER_CACHE = [String: [VerseInfo]]()
        }
        CHAPTER_CACHE["\(self.bookNo!)\(self.chapterNo!)"] = self.verses

    }
    
    func makeChapterVerse(verseNo: Int, verseText: String?) -> VerseInfo {
        let bookIdStr = String(format: "%02d", self.bookNo!)
        let chapterId = String(format: "%03d", Int(self.chapterNo!))
        let verseId = String(format: "%03d", verseNo)
        let id = "\(bookIdStr)\(chapterId)\(verseId)"
        let bookName = Books(rawValue: self.bookNo!)!.name()
        let chName = "\(bookName) \(chapterNo!):\(verseNo)"
        let chapterVerse = VerseInfo.init(id: id, name: chName, text: verseText)
        chapterVerse.bookNo = self.bookNo
        chapterVerse.chapterNo = self.chapterNo
        chapterVerse.verse = verseNo
        
        return chapterVerse
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
