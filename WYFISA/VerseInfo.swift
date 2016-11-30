//
//  VerseInfo.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/28/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import Foundation


enum ItemCategory: Int {
    
    case Verse = 0, Note, Image
    
    func name() -> String {
        switch self.rawValue {
        case 0:
            return "Avenir"
        case 1:
            return "Baskerville"
        case 2:
            return "Iowan"
        default:
            return "San Francisco"
        }
    }
    
}

class VerseInfo {
    let id: String
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
    
    init(id: String, name: String, text: String?){
        self.id = id
        self.name = name
        self.text = text
        self.ts =  NSDate().timeIntervalSince1970
        self.createdAt = self.ts.description
    }
    
    func toDocProperties() -> [String : AnyObject] {
        
        // optional values
        let text =  self.text ?? ""
        let chapter = self.chapter ?? ""
        let chapterNo = self.chapterNo ?? 0
        let bookNo = self.bookNo ?? 0
        let verse =  self.verse ?? 0
        
        // doc props
        let properties: [String : AnyObject] = ["id": self.id,
             "name": self.name,
             "priority": self.priority,
             "session": NSNumber(unsignedLongLong: self.session),
             "text": text,
             "chapter": chapter,
             "chapterNo": chapterNo,
             "bookNo": bookNo,
             "verse": verse,
             "category": self.category.rawValue,
             "ts": self.ts,
             "createdAt": self.createdAt]
        
        return properties
    }
    
    class func DocPropertiesToObj(doc: AnyObject?) -> VerseInfo? {
        
        var verseInfo:VerseInfo? = nil
        
        if let verseDoc = doc as? [String: AnyObject] {
            let id = verseDoc["id"] as? String ?? ""
            let name = verseDoc["name"] as? String ?? ""
            let text = verseDoc["text"] as? String
            let v = VerseInfo.init(id: id, name: name, text: text)
   
            let categoryVal = verseDoc["category"] as? Int ?? 0
            if let category = ItemCategory(rawValue: categoryVal) {
                v.category = category
            }
            
            if let session = verseDoc["session"] as? NSNumber {
                v.session = session.unsignedLongLongValue
            }
            
            v.createdAt = verseDoc["createdAt"] as? String ?? ""
            v.priority = verseDoc["priority"] as? Float ?? -1
            v.chapter = verseDoc["chapter"] as? String ?? ""
            v.chapterNo = verseDoc["chapterNo"] as? Int ?? 0
            v.bookNo = verseDoc["bookNo"] as? Int ?? 0
            v.verse = verseDoc["verse"] as? Int ?? 0
            verseInfo = v
        }
        
        
        return verseInfo
    }
    
    /*
    func viewSpec() -> CBLView {
        let map = CBLMapBlock,
        return verseView.setMapBlock({ (doc, emit) in
            if let session = doc["session"] {
                emit(session, doc["id"])
            }
        }, version: "2")
    }
    */
}
