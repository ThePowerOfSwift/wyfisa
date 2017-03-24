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
                    print("No setup for", databaseName)
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
        
        let verseIdView = db?.viewNamed("verseById")
        verseIdView?.setMapBlock({ (doc, emit) in
            if let vkey = doc["key"] {
                emit(doc["id"]!, vkey)
            }
            }, version: "1")
        
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
        
        let topicsForOwner = db?.viewNamed("topicsForOwner")
        topicsForOwner?.setMapBlock({ (doc, emit) in
            if let doc_type = doc["type"] {
                if doc_type as! String == "topic" {
                    emit(doc["owner"]!, doc["_id"])
                }
            }
        }, version: "2")

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
    
    func getVerseDoc(key: String) -> VerseInfo? {  // by doc.key
        var verse:VerseInfo? = nil
        if let doc = self.db?.documentWithID(key) {
            verse = VerseInfo.DocPropertiesToObj(doc.properties)
        }
        return verse
    }
    
    func getVerseDocById(id: String) -> VerseInfo? {  // by doc.id
        var verse:VerseInfo? = nil
        
        if let db = self.db {
            let query = db.viewNamed("verseById").createQuery()
            query.keys = [id]

            do {
                let result = try query.run()
                if result.count > 0 {
                    let row = result.rowAtIndex(0)
                    let key = row.value as! String
                    verse = self.getVerseDoc(key)
                }
            } catch {}
        }
        return verse
    }
    
    func getScriptDoc(id: String) -> ScriptDoc? {
        var script:ScriptDoc? = nil
        if let doc = self.db?.documentWithID(id) {
            if let properties = doc.properties {
                script = ScriptDoc.DocPropertiesToObj(properties)
            }
        }
        return script
    }

    func getTopicDoc(id: String) -> TopicDoc? {
        var topic:TopicDoc? = nil
        if let doc = self.db?.documentWithID(id) {
            if let properties = doc.properties {
                topic = TopicDoc.DocPropertiesToObj(properties)
            }
        }
        return topic
    }
    

    func getTopicsForOwner(ownerId: String) -> [TopicDoc] {
        var topics: [TopicDoc] = [TopicDoc]()
        
        if let db = self.db {
            let query = db.viewNamed("topicsForOwner").createQuery()
            query.keys = [ownerId]
            do {
                let result = try query.run()
                while let row = result.nextRow() {
                    let topicId = row.value as! String
                    if let topic = self.getTopicDoc(topicId){
                        topics.append(topic)
                    }
                }
            } catch {}
        }
        
        topics.sortInPlace{ s1, s2 in return s1.title < s2.title }
        return topics
    }
    
    func getRecentTopic(ownerId: String) -> TopicDoc? {
        let topics = self.getTopicsForOwner(ownerId)
        
        // needs to sort by last updated
        if topics.count > 0 {
            return topics[0]
        }
        return nil
    }
    
    func getScriptsForTopic(topicId: String) -> [ScriptDoc] {
        var topicScripts: [ScriptDoc] = [ScriptDoc]()
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
                        verse.imageCropped = self.getImageAttachment(verse.key, named: "cropped.jpg")
                        verse.overlayImage = self.getImageAttachment(verse.key, named: "overlay.png")
                        scriptVerses.append(verse)
                    }
                }
            } catch {}
        }
        return scriptVerses
    }

    
    func deleteScript(script: ScriptDoc){

        // get verses
        let verses = self.getVersesForScript(script.id)
        
        // remove verses
        for verse in verses {
            self.removeDoc(verse.key)
        }
        
        // delete script
        self.removeDoc(script.id)
    }
    
    func deleteTopic(topic: TopicDoc){
        // remove scripts
        let scripts = self.getScriptsForTopic(topic.id)
        for script in scripts {
            self.deleteScript(script)
        }
        
        // delete topic
        self.removeDoc(topic.id)
    }
    func putTopic(topic: TopicDoc){
        Timing.runAfter(0){
            self._putTopic(topic)
        }
    }
    
    private func _putTopic(topic: TopicDoc) {
        
        if let doc = db?.existingDocumentWithID(topic.id) {
            do {
                try doc.update({
                    (newRevision) -> Bool in
                    newRevision["title"] = topic.title
                    return true
                })
            } catch {
                print("update topic failed")
            }
        } else if let doc = db?.documentWithID(topic.id) {
            let properties =  topic.toDocProperties()
            do {
                try doc.putProperties(properties)
            } catch {
                print("save topic failed")
            }
        }
    }
    
    func putScript(script: ScriptDoc){
        Timing.runAfter(0){
            self._putScript(script)
        }
    }
    
    private func _putScript(script: ScriptDoc) {
        
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
                    self.attachImage(doc, image: verse.imageCropped, named: "cropped.jpg")
                    self.attachImage(doc, image: verse.overlayImage, named: "overlay.png", format: "png")
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
    
    
    func attachImage(doc: CBLDocument, image: UIImage?, named: String, format: String? = "jpg"){
        
        // attach image
        if let rev = doc.currentRevision {
            var newRev = rev.createRevision()
            if let img = image {
                if format == "jpg" {
                    let imageData = UIImageJPEGRepresentation(img, 0.70)
                    newRev.setAttachmentNamed(named, withContentType: "image/jpeg", content: imageData)
                }
                if format == "png" {
                    let imageData =  UIImagePNGRepresentation(img)
                    newRev.setAttachmentNamed(named, withContentType: "image/png", content: imageData)
                }
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
    
    func updateVerseImage(verse: VerseInfo){
        
        if let doc = db?.existingDocumentWithID(verse.key) {
            do {
                try doc.update({
                    (newRevision) -> Bool in
                    newRevision["cropOffset"] = verse.imageCroppedOffset
                    newRevision["highlighted"] = verse.isHighlighted
                    return true
                })
            } catch {
                print("update doc failed")
            }
            self.attachImage(doc, image: verse.imageCropped, named: "cropped.jpg")
        }
    }

    func updateVerse(verse: VerseInfo){
        
        let id = verse.key

        switch verse.category {
        case .Note:
            self.updateVerseNote(id, note: verse.name)
        case .Image:
            break
            // self.updateVerseImage(verse)
        case .Verse:
            // updating verse just means to sync it's version with text we have
            verse.version = SettingsManager.sharedInstance.version.text()
            self.updateVerseTextVersion(id, text: verse.text!, version: verse.version)

        }
    }
    
    func removeDoc(id: String){
        if let doc = db?.existingDocumentWithID(id) {
            do {
                try doc.deleteDocument()
            } catch {
                print("delete doc failed")
            }
            
        }
 
    }
    

}
