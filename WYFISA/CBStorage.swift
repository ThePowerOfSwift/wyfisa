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
   // let firedb: FBStorage = FBStorage.sharedInstance
    
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
                        verse.image = self.getImageAttachment(verse.createdAt, named: "original.jpg")
                        verse.overlayImage = self.getImageAttachment(verse.createdAt, named: "overlay.jpg")
                        verse.accessoryImage = self.getImageAttachment(verse.createdAt, named: "accessory.jpg")
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
                if verse.category == .Image {
                    self.attachImage(doc, image: verse.image, named: "original.jpg")
                    self.attachImage(doc, image: verse.overlayImage, named: "overlay.jpg")
                    self.attachImage(doc, image: verse.accessoryImage, named: "accessory.jpg")
                }
            } catch {
                print("save verse failed")
            }
        }
    }
    
    func getAttachment(key: String, named: String) -> NSData? {
        
        var data: NSData?
        if let db = self.db {
            if let doc = db.documentWithID(key) {
                if let rev = doc.currentRevision {
                    let att = rev.attachmentNamed(named)
                    data = att?.content
                }
            }
        }
        
        return data
    }
    
    func getImageAttachment(key: String, named: String) -> UIImage? {
        if let imgData =  self.getAttachment(key, named: named) {
            return UIImage(data: imgData)
        }
        return nil
    }
    
    func attachImage(doc: CBLDocument, image: UIImage?, named: String)  {
        
        // attach image
        if let rev = doc.currentRevision {
            let newRev = rev.createRevision()
            
            if let img = image {
                let imageData = UIImageJPEGRepresentation(img, 0.75)
                newRev.setAttachmentNamed(named, withContentType: "image/jpeg", content: imageData)
                do {
                    try newRev.save()
                } catch {
                    print("attach image failed")
                }
            }
        }
    }
    
    func updateVerseNote(id: String, note: String){

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
