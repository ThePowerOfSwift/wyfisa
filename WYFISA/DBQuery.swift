//
//  DBQuery.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/14/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import SQLite

class DBQuery {
    let conn: Connection
    
    init(){
        let path = NSBundle.mainBundle().pathForResource("bible-sqlite", ofType: "db")!
        self.conn = try! Connection(path, readonly: true)
    }
    
    func lookupVerse(verseId: String) -> String? {
        var verse: String?
        let bible = Table("t_web")
        let id = Expression<String>("id")
        let text = Expression<String>("t")
        let query = bible.select(text).filter(id == verseId)
        if let row = conn.pluck(query) {
            verse = row.get(text)
        }
        
        return verse
    }
    
}