//
//  DBQuery.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/14/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import SQLite


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

    init(){
        var path = NSBundle.mainBundle().pathForResource("t_kjv", ofType: "db")!
        self.conn = try! Connection(path, readonly: true)
        path = NSBundle.mainBundle().pathForResource("cross_ref", ofType: "db")!
        self.refconn = try! Connection(path, readonly: true)
    }
    
    func lookupVerse(verseId: String) -> String? {
        var verse: String?
        
        let query = bibleTable.select(bibleCol.text).filter(bibleCol.id == verseId)
        if let row = conn.pluck(query) {
            verse = row.get(bibleCol.text)
            verse = self.stripText(verse!)
        }
        
        return verse
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
        var n:Int = 0
        let query = bibleTable.select(bibleCol.verse)
            .filter(bibleCol.book == bookId && bibleCol.chapter == chapterId)
        do {
            let all = Array(try conn.prepare(query))
            n = all.count
        } catch {}
        return n
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
        
        // check if next chapter has verses
        var bookNo = bookId
        var chapterNo = chapterId - 1
        if let book = Books(rawValue: bookNo) {
            if chapterNo == 0 { // check if previous book has verses
                bookNo = bookId-1
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
        
        // get book and chapter
        var query = bibleTable.select(bibleCol.book, bibleCol.chapter, bibleCol.verse).filter(bibleCol.id == verseId)
        if let row = conn.pluck(query) {
            let bookId = row.get(bibleCol.book)
            let chapterId = row.get(bibleCol.chapter)
            let verseId = row.get(bibleCol.verse)
            
            // query for text
            query = bibleTable.select(bibleCol.text)
                .filter(bibleCol.book == bookId && bibleCol.chapter == chapterId)
            
            let bookName = Books(rawValue: bookId)!.name()
            
            do {
                var i = 1
                for row in try conn.prepare(query) {
                    var rc = self.stripText(row.get(bibleCol.text))
                    
                    // create verse singleton
                    let verseName = self.createVerseName(bookId, chapterNo: chapterId, verseNo: i)!
                    let id = self.createVerseId(bookId, chapterNo: chapterId, verseNo: i)
                    let verseInfo = VerseInfo.init(id: id, name: verseName, text: rc)
                    verseInfo.verse = i
                    verseInfo.bookNo = bookId
                    verseInfo.chapterNo = chapterId
                    verseInfo.verse = i
                    chapterVerses.append(verseInfo)

                    if (i == verseId){ // this is context verse
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

                    i+=1
                    
                }
            } catch { print("query error") }

        }
        self.verseCache[verseId] = chapterVerses
        self.chapterCache[verseId] = chapter
        return chapter
    }

    func crossReferencesForVerse(verseId: String) -> [VerseInfo] {
        
        if let cachedReferences = self.refCache[verseId] {
            return cachedReferences
        }
        
        var references = [VerseInfo]()
        
        var query = self.crossRefTable.select(crossRefCol.rank, crossRefCol.start_verse, crossRefCol.end_verse)
            .filter(crossRefCol.vid == verseId)
            .order(crossRefCol.rank.desc)
            .limit(10)
        
        do {
            for row in try refconn.prepare(query) {
                                
                // query start to end verse for reference
                let startId = String(row.get(crossRefCol.start_verse))
                var endId = String(row.get(crossRefCol.end_verse))
                
                if endId == "0" {
                    endId = startId
                }
                
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

            
            }
        } catch { print("query error") }
        
        self.refCache[verseId] = references
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
        let refs = self.crossReferencesForVerse(verse.id)
        let verses = self.versesForChapter(verse.id)
        verse.chapter = chapter
        verse.refs = refs
        verse.verses = verses
        verse.bookNo = bookNo
        verse.chapterNo = chapterNo
        verse.verse = verseNo
        return verse
    }
    
}
