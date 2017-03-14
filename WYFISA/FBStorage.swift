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

@objc protocol FBStorageDelegate: class {
    optional func didGetSingleVerse(sender: AnyObject, verse: AnyObject)
    optional func didGetSingleVerseForRow(sender: AnyObject, verse: AnyObject, section: Int)
    optional func didGetVerseContext(sender: AnyObject, verses: [AnyObject])
}


class FBStorage {
    var storage: FIRStorage
    let storageRef: FIRStorageReference
    let databaseRef: FIRDatabaseReference
    weak var delegate:FBStorageDelegate?
    let settings = SettingsManager.sharedInstance


    init(){
        self.storage = FIRStorage.storage()
        self.storageRef = storage.referenceForURL("gs://turnto-26933.appspot.com")
        self.databaseRef = FIRDatabase.database().reference()
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
        let version = settings.version.text()
        var context:[VerseInfo] = []
        
        let bookIdStr = String(format: "%02d", bookNo)
        let chapterStartId = String(format: "%03d", chapterNo)
        let chapterEndId = String(format: "%03d", chapterNo+1)
        let verseId = String("001")
        let startId = "\(bookIdStr)\(chapterStartId)\(verseId)"
        let endId = "\(bookIdStr)\(chapterEndId)\(verseId)"

        self.databaseRef.child(version)
            .queryOrderedByKey()
            .queryStartingAtValue(startId)
            .queryEndingAtValue(endId)
            .observeSingleEventOfType(.Value, withBlock: { (data) in
                // convert value to verse(s)
                if let snapshots = data.value as?  [String : AnyObject] {
                    for var snapshot in snapshots.values {
                        if let verse = VerseInfo.DocPropertiesToObj(snapshot) {
                            context.append(verse)
                        }
                    }
                    context.sortInPlace{ s1, s2 in return s1.id < s2.id }
                    self.delegate?.didGetVerseContext?(self, verses: context)
                }
            })
    }
    
    
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
            let observer = uploadTask.observeStatus(.Success) { snapshot in
                // ok
                print("uploaded", path)
            }
            
        }
    }
}
