//
//  DBManager.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/29/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

enum StorageReplicationMode {
    case Push, Pull, Dual
}

class CBStorage {
    
    var db: CBLDatabase?  = nil
    var push: CBLReplication?
    var pull: CBLReplication?
    var auth: CBLAuthenticatorProtocol?
    var databaseName: String
    var updateLock = NSLock()

    class func MakeCBStorage(databaseName: String) -> CBStorage {
        let storage = CBStorage(databaseName: databaseName)
        
        switch databaseName {
        case SCRIPTS_DB:
            storage.replicate(.Dual)
            storage.createScriptView()
        default:
            print("UNKNOWN DB", databaseName)
        }
        
        return storage

    }
    init(databaseName: String, skipSetup: Bool = false){
        self.databaseName = databaseName
        do {
            let db = try CBLManager.sharedInstance().databaseNamed(databaseName)
            self.db = db
            // try db.deleteDatabase()
            
            // setup db based on type
            if skipSetup == false {
                switch databaseName {
                case SCRIPTS_DB:
                    self.replicate(.Dual)
                    self.createScriptView()
                default:
                    print("UNKNOWN DB", databaseName)
                }
            }
        } catch {
            // TODO: Handle this can be really bad!
            print("Unable to create database")
        }

        
    }
    
    func authUser(uid: String, password: String){
        self.auth = CBLAuthenticator
            .basicAuthenticatorWithName(uid,
                                        password: password)
    }
    
    
    func verseByScript(){
        
    }
    func createScriptView(){
        
        // create views
        let verseView = db?.viewNamed("versesByCreated")
        verseView?.setMapBlock({ (doc, emit) in
            if let ts = doc["createdAt"] {
                emit(ts, doc)
            }
            }, version: "2")
        
        let scriptView = db?.viewNamed("scriptVerses")
        scriptView?.setMapBlock({ (doc, emit) in
            if let scriptId = doc["script"] {
                emit(scriptId, doc["_id"])
            }
            }, version: "3")
        
        let scriptsForTopic = db?.viewNamed("scriptsForTopic")
        scriptsForTopic?.setMapBlock({ (doc, emit) in
            if let topicId = doc["topic"] {
                emit(topicId, doc["_id"])
            }
            }, version: "1")
    }
    
    func createBibleViews(){
        
        // create views
        let verseView = db?.viewNamed("versesByCh")
        verseView?.setMapBlock({ (doc, emit) in
            if let book = doc["book"] {
                if let chapter = doc["chapter"] {
                    emit( [book as! Int, chapter as! Int], doc["id"])
                }
            }
            }, version: "3")
    }
    
    func getChapterVerses(bookNo: Int, chapterNo: Int) -> [String]{
        var verses: [String] = []
        
        
        if let db = self.db {
            let query = db.viewNamed("versesByCh").createQuery()
            query.keys = [[bookNo, chapterNo]]
            do {
                let result = try query.run()
                while let row = result.nextRow() {
                    let verse = row.value
                    /*
                    if let verse = VerseInfo.DocPropertiesToObj(doc) {
                        verse.image = self.getImageAttachment(verse.createdAt, named: "original.jpg")
                        verse.overlayImage = self.getImageAttachment(verse.createdAt, named: "overlay.jpg")
                        verse.accessoryImage = self.getImageAttachment(verse.createdAt, named: "accessory.jpg")
                        recentVerses.append(verse)
                    }*/
                }
            } catch {}
        }
        return verses
    }
    
    func replicate(mode: StorageReplicationMode){
        
        if self.auth == nil {
            return // not authenticated
        }
        
        let url = NSURL(string: "http://10.0.0.5:4984/\(self.databaseName)")!
        
        switch mode {
        case .Push:
            self.push = self.db?.createPushReplication(url)
        case .Pull:
            self.pull = self.db?.createPullReplication(url)
        case .Dual:
            self.push = self.db?.createPushReplication(url)
            self.pull = self.db?.createPullReplication(url)
        }
        self.push?.continuous = true
        self.pull?.continuous = true
        self.push?.authenticator = self.auth
        self.pull?.authenticator = self.auth
        self.push?.start()
        self.pull?.start()
        
    }
    
    func getVerseDoc(id: String) -> VerseInfo? {
        var verse:VerseInfo? = nil
        if let doc = self.db?.documentWithID(id) {
            verse = VerseInfo.DocPropertiesToObj(doc.properties)
        }
        return verse
    }
    
    func getScriptDoc(id: String) -> UserScript? {
        var script:UserScript? = nil
        if let doc = self.db?.documentWithID(id) {
            if let properties = doc.properties {
                script = UserScript.DocPropertiesToObj(properties)
            }
        }
        return script
    }
    // func getUserTopics
    
    func getScriptsForTopic(topicId: String) -> [UserScript] {
        var topicScripts: [UserScript] = [UserScript]()
        if let db = self.db {
            let query = db.viewNamed("scriptsForTopic").createQuery()
            query.keys = [topicId]
            do {
                let result = try query.run()
                while let row = result.nextRow() {
                    let scriptId = row.value as! String
                    
                    if let script = self.getScriptDoc(scriptId) {
                        topicScripts.append(script)
                    }
                }
            } catch {}
        }
        
        topicScripts.sortInPlace{ s1, s2 in return s1.lastUpdated > s2.lastUpdated }

        return topicScripts
    }
    
    func getVersesForScript(scriptId: String) -> [VerseInfo]{
        var scriptVerses: [VerseInfo] = [VerseInfo]()
        if let db = self.db {
            let query = db.viewNamed("scriptVerses").createQuery()
            query.keys = [scriptId]
            do {
                let result = try query.run()
                while let row = result.nextRow() {
                    let verseId = row.value as! String

                    if let verse = self.getVerseDoc(verseId) {
                        verse.image = self.getImageAttachment(verse.key, named: "original.jpg")
                        verse.overlayImage = self.getImageAttachment(verse.key, named: "overlay.jpg")
                        verse.accessoryImage = self.getImageAttachment(verse.key, named: "accessory.jpg")
                        scriptVerses.append(verse)
                    }
                }
            } catch {}
        }
        return scriptVerses
    }

    func putScript(script: UserScript){
        Timing.runAfter(0){
            self._putScript(script)
        }
    }
    
    private func _putScript(script: UserScript) {
        
        if let doc = db?.documentWithID(script.id) {
            let properties =  script.toDocProperties()
            do {
                try doc.putProperties(properties)
            } catch {
                print("save script failed")
            }
        }
    }
    
    // put verse into a database
    func putVerse(verse: VerseInfo){
        Timing.runAfter(0){
            self._putVerse(verse)
        }
    }
    
    // non thread-safe implementation
    private func _putVerse(verse: VerseInfo) {
        // store in database
        if let doc = db?.documentWithID(verse.key) {
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
    
    func updateScriptTimestamp(id: String){
        let ts =  NSDate().timeIntervalSince1970.description
        if let doc = db?.existingDocumentWithID(id) {
            do {
                try doc.update({
                    (newRevision) -> Bool in
                    newRevision["lastUpdated"] = ts
                    return true
                })
            } catch {
                print("update doc failed")
            }
            
        }
    }
    func updateScriptCountAndTimestamp(id: String, counter: Int){
        self.updateScriptTimestamp(id)
        if let doc = db?.existingDocumentWithID(id) {
            do {
                try doc.update({
                    (newRevision) -> Bool in
                    newRevision["count"] = (newRevision["count"] as! Int) + counter
                    return true
                })
            } catch {
                print("update doc failed")
            }
            
        }
    }
    
    func incrementScriptCountAndTimestamp(id: String){
        self.updateScriptCountAndTimestamp(id, counter: 1)
    }
    
    func decrementScriptCountAndTimestamp(id: String){
        self.updateScriptCountAndTimestamp(id, counter: -1)
    }
    
    func updateScriptTitle(id: String, title: String){
        if let doc = db?.existingDocumentWithID(id) {
            do {
                try doc.update({
                    (newRevision) -> Bool in
                    newRevision["title"] = title
                    return true
                })
            } catch {
                print("update doc failed")
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
    
    func updateVerseTextVersion(id: String, text: String, version: String){
        
        updateLock.lock()
        if let doc = db?.existingDocumentWithID(id) {
            do {
                try doc.update({
                    (newRevision) -> Bool in
                    newRevision["text"] = text
                    newRevision["version"] = version
                    return true
                })
            } catch {
                print("update doc failed")
            }
            
        }
        updateLock.unlock()

    }
    
    func updateVerse(verse: VerseInfo){
        
        let id = verse.key

        switch verse.category {
        case .Note:
            self.updateVerseNote(id, note: verse.name)
        case .Image:
            break // TODO!!!! do something
        case .Verse:
            // updating verse just means to sync it's version with text we have
            verse.version = SettingsManager.sharedInstance.version.text()
            self.updateVerseTextVersion(id, text: verse.text!, version: verse.version)

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
