//
//  FireStorage.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/30/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation
import Firebase

class FBStorage {
    var storage: FIRStorage
    let ref: FIRStorageReference
    static let sharedInstance = FBStorage()

    init(){
        FIRApp.configure()
        self.storage = FIRStorage.storage()
        self.ref = storage.referenceForURL("gs://turnto-26933.appspot.com")
    }
    
    func upload(path: String, data: NSData, type: String?) -> FIRStorageUploadTask {
        
        let uploadRef = self.ref.child(path)
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
