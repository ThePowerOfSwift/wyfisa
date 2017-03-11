//
//  UserScript.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/11/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

class UserScript {
    var id: String
    var title: String
    var lastUpdated: String
    var count: Int = 0
    var owner: String
    var topic: String

    init(title: String, topic: String){
        self.title = title
        self.lastUpdated = NSDate().timeIntervalSince1970.description
        let seed = randomString(10)
        self.id = "\(self.lastUpdated)\(seed)"
        self.owner = "TODO"
        self.topic = topic
    }
    
    func toDocProperties() -> [String : AnyObject] {

        // doc props
        let properties: [String : AnyObject] = ["id": self.id,
                                                "title": self.title,
                                                "lastUpdated": self.lastUpdated,
                                                "count": self.count,
                                                "owner": self.owner,
                                                "topic": self.topic]
        return properties
    }
    
    class func DocPropertiesToObj(doc: [String: AnyObject]) -> UserScript? {

        let topic = doc["topic"] as! String
        let title = doc["title"] as! String
        let script = UserScript.init(title: title, topic: topic)
        script.id = doc["id"] as! String
        script.lastUpdated = doc["lastUpdated"] as! String
        script.count = doc["count"] as! Int
        script.owner = doc["owner"] as! String
        script.topic = doc["topic"] as! String
        return script
    }



}
