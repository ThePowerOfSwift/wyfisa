//
//  DBManager.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/29/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

class CBStorage {
    
    var db: CBLDatabase?  = nil

    init(databaseName: String){
        do {
            let db = try CBLManager.sharedInstance().databaseNamed(databaseName)
            self.db = db
           // try db.deleteDatabase()
            // create views
            let verseView = db.viewNamed("versesByCreated")
            verseView.setMapBlock({ (doc, emit) in
                if let ts = doc["createdAt"] {
                    emit(ts, doc)
                }
            }, version: "2")
            
        } catch {
            // TODO: Handle this can be really bad!
            print("Unable to create database")
        }
    }
    
    
    func getRecentVerses() -> [VerseInfo]{
        var recentVerses: [VerseInfo] = [VerseInfo]()
        if let db = self.db {
            let query = db.viewNamed("versesByCreated").createQuery()
            do {
                let result = try query.run()
                while let row = result.nextRow() {
                    let doc = row.value
                    if let verse = VerseInfo.DocPropertiesToObj(doc) {
                        recentVerses.append(verse)
                    }
                }
            } catch {}
        }
        return recentVerses
    }

    // put verse into a database
    func putVerse(verse: VerseInfo){
        Timing.runAfter(0){
            self._putVerse(verse)
        }
    }
    
    // non thread-safe implementation
    func _putVerse(verse: VerseInfo) {
        // store in database
        let key = verse.createdAt
        if let doc = db?.documentWithID(key) {
            let properties =  verse.toDocProperties()
            do {
                try doc.putProperties(properties)
            } catch {
                print("save verse failed")
            }
        }
    }
    
    func updateVerseNote(id: String, note: String){
        print("UPDATING", id, note)

        if let doc = db?.existingDocumentWithID(id) {
            do {
                try doc.update({
                    (newRevision) -> Bool in
                    newRevision["name"] = note
                    return true
                })
            } catch {
                print("update doc failed")
            }
            
        }
    }
    func updateVerse(verse: VerseInfo){
        
        let id = verse.createdAt

        switch verse.category {
        case .Note:
            self.updateVerseNote(id, note: verse.name)
        case .Image:
            break // do something
        case .Verse:
            break // cannot be updated

        }
    }
    
    func removeVerse(id: String){
        if let doc = db?.existingDocumentWithID(id) {
            do {
                try doc.deleteDocument()
            } catch {
                print("delete doc failed")
            }
            
        }
 
    }
    

}



/*
 let phoneView = db.viewNamed("phones")
 phoneView.setMapBlock({ (doc, emit) in
 if let phones = doc["phones"] as? [String] {
 for phone in phones {
 emit(phone, doc["name"])
 }
 }
 }, version: "2")
 */
