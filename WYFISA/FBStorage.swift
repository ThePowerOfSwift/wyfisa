//
//  FireStorage.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/30/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase


enum FBContextType: Int {
    case Chapter = 0, Range
}

@objc protocol FBStorageDelegate: class {
    optional func didGetSingleVerse(sender: AnyObject, verse: AnyObject)
    optional func didGetSingleVerseForRow(sender: AnyObject, verse: AnyObject, section: Int)
    optional func didGetVerseContext(sender: AnyObject, verses: [AnyObject], type: AnyObject)
    optional func didGetMatchIDs(sender: AnyObject, matches: [AnyObject])

}


class FBStorage {
    var storage: FIRStorage
    let storageRef: FIRStorageReference? = nil
    let databaseRef: FIRDatabaseReference
    weak var delegate:FBStorageDelegate?
    let settings = SettingsManager.sharedInstance


    init(){
        self.storage = FIRStorage.storage()
        self.databaseRef = FIRDatabase.database().reference()
    }
    
    func startSearchSession() -> String {
        let key = randomString(10)
        let ts =  NSDate().timeIntervalSince1970.description
        let sessionDoc = ["ts": ts,
                          "request": ""]
        self.databaseRef
            .child("query")
            .child(key)
            .setValue(sessionDoc)
        
        self.databaseRef
            .child("query")
            .child(key).child("response")
            .queryOrderedByChild("score")
            .observeEventType(.Value, withBlock: {(snapshot) in
                if let matches =  snapshot.value as? [[String:AnyObject]] {
                    // send out a query for each id
                    self.delegate?.didGetMatchIDs?(self, matches: matches)
                }
            })
        
        return key
    }
    
    func endSearchSession(key: String) {
        self.databaseRef.child("query").child(key).removeValue()
    }
    
    func updateSearchSession(key: String, text: String) {
        print("Query", key)
        self.databaseRef
            .child("query")
            .child(key)
            .child("request").setValue(text)
        
    }
    
    func getVerseDoc(id: String, section: Int? = nil) {
        let version = settings.version.text()
        self.databaseRef.child(version)
            .child(id)
            .observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                // convert value to verse
                let value = snapshot.value as?  [String : AnyObject]
                if let verse = VerseInfo.DocPropertiesToObj(value) {
                    verse.version = version
                    if section == nil {
                        self.delegate?.didGetSingleVerse?(self, verse: verse)
                    } else {
                        self.delegate?.didGetSingleVerseForRow?(self, verse: verse, section: section!)
                    }
                }
            })
    }
    
    
    func getVerseContext(bookNo: Int, chapterNo: Int) {

        let bookIdStr = String(format: "%02d", bookNo)
        let chapterStartId = String(format: "%03d", chapterNo)
        let chapterEndId = String(format: "%03d", chapterNo+1)
        let verseId = String("001")
        let startId = "\(bookIdStr)\(chapterStartId)\(verseId)"
        let endId = "\(bookIdStr)\(chapterEndId)\(verseId)"

        self.getVerseRange(startId, endId, type: .Chapter)

    }
    
    func getVerseRange(from: String, _ to: String, type: FBContextType = .Range){
        
        let version = settings.version.text()
        var context:[VerseInfo] = []
    
        self.databaseRef.child(version)
            .queryOrderedByKey()
            .queryStartingAtValue(from)
            .queryEndingAtValue(to)
            .observeSingleEventOfType(.Value, withBlock: { (data) in
                // convert value to verse(s)
                if let snapshots = data.value as?  [String : AnyObject] {
                    for snapshot in snapshots.values {
                        if let verse = VerseInfo.DocPropertiesToObj(snapshot) {
                            context.append(verse)
                        }
                    }
                    context.sortInPlace{ s1, s2 in return s1.id < s2.id }
                    self.delegate?.didGetVerseContext?(self, verses: context, type: type.rawValue)
                }
            })
    }
    
    func getInterlinearDoc(id: String) {

        self.databaseRef.child("interlinear")
            .child(id)
            .observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                // convert value to verse
                if let value = snapshot.value as?  [String : AnyObject]{
                    let verse = InterlinearVerse.initFromSnapshot(value)
                    self.delegate?.didGetSingleVerse?(self, verse: verse)
                }
            })
    }
    
    /*
    func upload(path: String, data: NSData, type: String?) -> FIRStorageUploadTask {
        
        let uploadRef = self.storageRef.child(path)
        let meta = FIRStorageMetadata()
        meta.contentType = type
        
        // Upload the file to the path "images/<id>"
        return  uploadRef.putData(data, metadata: meta)
    }
    
    func uploadImage(image: UIImage?, id: String){
        if image == nil { return }
        
        if let data = UIImageJPEGRepresentation(image!, 0.70) {
            let suffix = randomString(6)
            let path = "images/\(id)_\(suffix).jpg"
            let uploadTask = self.upload(path, data: data, type: "image/jpeg")
            let _ = uploadTask.observeStatus(.Success) { snapshot in
                // ok
                print("uploaded", path)
            }
            
        }
    }
    */
}
