//
//  DBQuery.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/14/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import SQLite
import Regex

struct VerseRange {
    let from: String
    let to: String
}

struct BibleTableColumns {
    let id = Expression<String>("id")
    let text = Expression<String>("t")
    let book = Expression<Int>("b")
    let chapter = Expression<Int>("c")
    let verse = Expression<Int>("v")
}

struct CrossRefColumns {
    let vid = Expression<String>("vid")
    let rank = Expression<Int>("r")
    let start_verse = Expression<Int>("sv")
    let end_verse = Expression<Int>("ev")
}

class DBQuery {
    
    // is singleton
    static let sharedInstance = DBQuery()
    let conn: Connection
    let refconn: Connection
    let bibleTable = Table("t_kjv")
    let bibleCol = BibleTableColumns()
    let crossRefTable = Table("cross_reference")
    let crossRefCol = CrossRefColumns()
    var chapterCache = [String:String]()
    var refCache = [String:[VerseInfo]]()
    var verseCache = [String:[VerseInfo]]()
    var storage: CBStorage = CBStorage(databaseName: "bibles")
    
    init(){
        self.conn = try! Connection("", readonly: true)
        let path = NSBundle.mainBundle().pathForResource("cross_ref", ofType: "db")!
        self.refconn = try! Connection(path, readonly: true)

        
    }
    
    func lookupVerse(verseId: String) -> String? {
        var text: String?
        
        if let verse = self.storage.getVerseDoc(verseId){
            text = verse.text
        }
        
        // otherwise get it from api bc we haven't sync'd yet
        
        return text
    }
    
    func versesForChapter(verseId: String) -> [VerseInfo] {
        
        if let cachedVerses = self.verseCache[verseId] {
            return cachedVerses
        }
        
        // chapterForVerse builds the verse cache
        self.chapterForVerse(verseId)
        if let cachedVerses = self.verseCache[verseId] {
            return cachedVerses
        } else {
            return [VerseInfo]()
        }
    }
    
    func numChapterVerses(bookId: Int, chapterId: Int) -> Int {
        return BooksData.sharedInstance.numVerses(bookId, chapter: chapterId)!
    }
    
    func nextChapter(bookId: Int, chapterId: Int) -> VerseInfo? {
        
        // check if next chapter has verses
        var chapterNo = chapterId+1
        var bookNo = bookId
        if let book = Books(rawValue: bookNo) {
            if chapterNo > book.chapters() {// check if next book has verses
                chapterNo = 1
                bookNo = bookId+1
                let n = self.numChapterVerses(bookNo, chapterId: chapterNo)
                if n == 0 { // end of bible!
                    return nil
                }
            }
        }

        // create verseInfo
        return self.createVerseInfo(bookNo, chapterNo: chapterNo, verseNo: 1)

    }
    
    func prevChapter(bookId: Int, chapterId: Int) -> VerseInfo? {
        
        // check if prev chapter has verses
        var bookNo = bookId
        var chapterNo = chapterId - 1
        if Books(rawValue: bookNo) != nil {
            if chapterNo == 0 { // check if previous book has verses
                bookNo = bookId-1
                if bookNo == 0 {
                    return nil
                }
                if let lastBook = Books(rawValue: bookNo) {
                    chapterNo = lastBook.chapters()-1
                    let n = self.numChapterVerses(bookNo, chapterId: chapterNo)
                    if n == 0 {
                        return nil
                    }
                }
            }
        }
        
        // create verseInfo
        return self.createVerseInfo(bookNo, chapterNo: chapterNo, verseNo: 1)

    }
    
    func chapterForVerse(verseId: String) -> String {
        var chapter: String = ""
        var chapterVerses = [VerseInfo]()

        if let cachedChapter = self.chapterCache[verseId] {
            return cachedChapter
        }
        
        let verseParts = self.verseParts(verseId)
        if verseParts.count != 3 {
            return ""
        }
        
        let bookNo = verseParts[0]
        let chapterNo = verseParts[1]
        let verseNo = verseParts[2]
        var i = 1
        while true {
            let bookIdStr = String(format: "%02d", bookNo)
            let chapterStr = String(format: "%03d", chapterNo)
            let verseStr = String(format: "%03d", i)
            let id = "\(bookIdStr)\(chapterStr)\(verseStr)"
            if let verse = self.storage.getVerseDoc(id){
                verse.name = self.createVerseName(bookNo, chapterNo: chapterNo, verseNo: i)!
                verse.verse = i
                verse.bookNo = bookNo
                verse.chapterNo = chapterNo
                chapterVerses.append(verse)
                
                if var rc = verse.text {
                    if (i == verseNo){ // this is context verse
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
                    chapter = chapter.stringByAppendingString(rc)
                }
            } else {
                break
            }
            i += 1
        }
        
        self.verseCache[verseId] = chapterVerses
        self.chapterCache[verseId] = chapter
        return chapter
    }

    func crossReferencesForVerse(verseId: String) -> [VerseRange] {
        
        var references = [VerseRange]()
        
        let query = self.crossRefTable.select(crossRefCol.rank, crossRefCol.start_verse, crossRefCol.end_verse)
            .filter(crossRefCol.vid == verseId)
            .order(crossRefCol.rank)
            .limit(10)
        
        do {
            for row in try refconn.prepare(query) {
                                
                // query start to end verse for reference
                let startId = String(row.get(crossRefCol.start_verse))
                var endId = String(row.get(crossRefCol.end_verse))
                
                if endId == "0" {
                    endId = startId
                }
                let range = VerseRange(from: startId, to: endId)
                references.append(range)

                /*
                let verseInfo = VerseInfo.init(id: startId, name: "pending", text: nil)
                var passage: String?
                var refText: String = ""
    
                query = self.bibleTable.filter(bibleCol.id >= startId && bibleCol.id <= endId)
                var offset = 0
                var firstVerse = -1
                
                
                for row in try conn.prepare(query) {

                    // unpack passage vars
                    let bookNo = row.get(bibleCol.book)
                    let verseNo = row.get(bibleCol.verse)
                    let chapterNo = row.get(bibleCol.chapter)
                    if firstVerse == -1 {
                        firstVerse = verseNo
                    }
                    verseInfo.bookNo = bookNo
                    verseInfo.chapterNo = chapterNo
                    verseInfo.verse = firstVerse
                    if let book = Books(rawValue: bookNo){
                        let bookName = book.name()
                        if startId == endId {
                            passage = "\(bookName) \(chapterNo):\(verseNo)"
                        } else {
                            let startVerseNo = verseNo - offset
                            if startVerseNo <= 0 { // cross chapters
                                passage = "\(bookName) \(chapterNo):\(firstVerse)ff"
                            } else {
                                passage = "\(bookName) \(chapterNo):\(firstVerse)-\(verseNo)"
                            }
                        }
                    }
                    
                    
                    // append text
                    var text = self.stripText(row.get(bibleCol.text))
                    if startId != endId {
                        if offset > 0 {
                            text = "  \(verseNo) ".stringByAppendingString(text)
                        }
                    }
                    refText = refText.stringByAppendingString(text)
                    offset += 1
                }
                
                if passage != nil {
                    verseInfo.name = passage!
                    verseInfo.text = refText
                    verseInfo.verse = firstVerse
                    references.append(verseInfo)
                }
                */
            
            }
        } catch { print("query error") }
        
        // self.refCache[verseId] = references
        return references
    }
    
    func clearCache() {
        self.chapterCache = [String:String]()
        self.refCache = [String:[VerseInfo]]()
    }
    
    func stripText(text: String) -> String {
        
        return text.strip("\\")
            .replace("{", with: "(").replace("}", with: ")")
            .strip("&gt; ").strip("&lt; ")
 
    }
    
    func verseParts(verseId: String) -> [Int] {
        var parts:[Int] = []
        let pattern: Regex = Regex("(\\d{2})(\\d{3})(\\d{3})")
        let match = pattern.match(verseId)

        if let book = match?.captures[0] {
            parts.append(Int(book)!)
        }
        if let chapter = match?.captures[1] {
            parts.append(Int(chapter)!)
        }
        if let verse = match?.captures[2] {
            parts.append(Int(verse)!)
        }
        
        return parts
    }
    func createVerseId(bookNo: Int, chapterNo: Int, verseNo: Int) -> String {
        let bookIdStr = String(format: "%02d", bookNo)
        let chapterId = String(format: "%03d", chapterNo)
        let vid = String(format: "%03d", verseNo)
        return "\(bookIdStr)\(chapterId)\(vid)"
    }
    
    func createVerseName(bookNo: Int, chapterNo: Int, verseNo: Int) -> String? {
        var name:String? = nil
        if let book = Books(rawValue: bookNo) {
            let bookName = book.name()
            name = "\(bookName) \(chapterNo):\(verseNo)"
        }
        return name
    }
    
    func createVerseInfo(bookNo: Int, chapterNo: Int, verseNo: Int) -> VerseInfo {
        
        let verseName = self.createVerseName(bookNo, chapterNo: chapterNo, verseNo: 1)!
        let id = self.createVerseId(bookNo, chapterNo: chapterNo, verseNo: 1)
        let verse = VerseInfo.init(id: id, name: verseName, text: nil)
        
        let chapter = self.chapterForVerse(verse.id)
        let verses = self.versesForChapter(verse.id)
        verse.chapter = chapter
        verse.verses = verses
        verse.bookNo = bookNo
        verse.chapterNo = chapterNo
        verse.verse = verseNo
        return verse
    }
    
}
