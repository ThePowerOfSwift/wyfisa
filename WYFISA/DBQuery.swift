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
    let bibleTable = Table("t_web")
    let bibleCol = BibleTableColumns()
    let crossRefTable = Table("cross_reference")
    let crossRefCol = CrossRefColumns()
    
    init(){
        let path = NSBundle.mainBundle().pathForResource("bible-sqlite", ofType: "db")!
        self.conn = try! Connection(path, readonly: true)
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
    
    func chapterForVerse(verseId: String) -> String {
        var chapter: String = ""
        
        // get book and chapter
        var query = bibleTable.select(bibleCol.book, bibleCol.chapter).filter(bibleCol.id == verseId)
        if let row = conn.pluck(query) {
            let bookId = row.get(bibleCol.book)
            let chapterId = row.get(bibleCol.chapter)
            
            // query for text
            query = bibleTable.select(bibleCol.text)
                .filter(bibleCol.book == bookId && bibleCol.chapter == chapterId)
            do {
                var i = 1
                for row in try conn.prepare(query) {
                    var rc = self.stripText(row.get(bibleCol.text))
                    rc = "  \(i) \(rc)"
                    chapter = chapter.stringByAppendingString(rc)
                    i+=1
                }
            } catch { print("query error") }

        }
        return chapter
    }

    func crossReferencesForVerse(verseId: String) -> [VerseInfo] {
        var references = [VerseInfo]()
        
        var query = self.crossRefTable.select(crossRefCol.rank, crossRefCol.start_verse, crossRefCol.end_verse)
            .filter(crossRefCol.vid == verseId)
            .order(crossRefCol.rank.desc)
            .limit(10)
        
        do {
            for row in try conn.prepare(query) {
                                
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
                for row in try conn.prepare(query) {

                    // unpack passage vars
                    let bookNo = row.get(bibleCol.book)
                    let verseNo = row.get(bibleCol.verse)
                    let chapterNo = row.get(bibleCol.chapter)
                    if let book = Books(rawValue: bookNo){
                        let bookName = book.pattern().componentsSeparatedByString("|")[0]
                        if startId == endId {
                            passage = "\(bookName) \(chapterNo):\(verseNo)"
                        } else {
                            let startVerseNo = verseNo - offset
                            passage = "\(bookName) \(chapterNo):\(startVerseNo)-\(verseNo)"
                        }
                    }
                    
                    // append text
                    let text = self.stripText(row.get(bibleCol.text))
                    refText = refText.stringByAppendingString("  \(verseNo) \(text)")
                    offset += 1
                }
                
                if passage != nil {
                    verseInfo.name = passage!
                    verseInfo.text = refText
                    references.append(verseInfo)
                }

            
            }
        } catch { print("query error") }
        
        return references
    }
    
    func stripText(text: String) -> String {
        
        var t = text.stringByReplacingOccurrencesOfString("\\",
                                                         withString: "",
                                                         options: NSStringCompareOptions.LiteralSearch, range: nil)
        t =  t.stringByReplacingOccurrencesOfString("{",
            withString: "(",
            options: NSStringCompareOptions.LiteralSearch, range: nil)
        t =  t.stringByReplacingOccurrencesOfString("}",
                                                    withString: ")",
                                                    options: NSStringCompareOptions.LiteralSearch, range: nil)
        return t
 
    }
    
}