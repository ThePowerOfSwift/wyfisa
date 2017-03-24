//
//  UserScript.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/11/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit
import SwiftMoment

class OwnerDoc {
    var id: String  // sg replication id, this will get pushed to firebase on login
    var name: String?
    
    init(){
        let ts = NSDate().timeIntervalSince1970.hashValue
        let seed = randomString(10)
        self.id = "\(ts)-\(seed)"
    }
}

class TopicDoc {
    var id: String
    var owner: String
    var title: String?
    var lastUpdated: String
    var type = "topic"

    init(owner: String){
        self.owner = owner
        self.lastUpdated = NSDate().timeIntervalSince1970.description
        self.id = "\(lastUpdated)\(self.owner)"
    }
    
    
    func toDocProperties() -> [String : AnyObject] {
        
        // doc props
        let properties: [String : AnyObject] = ["id": self.id,
                                                "title": self.title ?? "",
                                                "lastUpdated": self.lastUpdated,
                                                "owner": self.owner,
                                                "type": self.type]
        return properties
    }
    
    class func DocPropertiesToObj(doc: [String: AnyObject]) -> TopicDoc? {
        
        let owner = doc["owner"] as! String
        let topic = TopicDoc.init(owner: owner)
        topic.id = doc["id"] as! String
        topic.lastUpdated = doc["lastUpdated"] as! String
        if let title = doc["title"] as? String {
            topic.title = title
        }

        return topic
    }
}

class ScriptDoc {
    var id: String
    var title: String
    var lastUpdated: String
    var count: Int = 0
    var owner: String
    var topic: String
    var type = "script"


    init(title: String, topic: String){
        self.title = title
        self.lastUpdated = NSDate().timeIntervalSince1970.description
        let seed = randomString(10)
        self.id = "\(self.lastUpdated)\(seed)"
        self.topic = topic
        self.owner = "TODO"
    }
    
    func toDocProperties() -> [String : AnyObject] {

        // doc props
        let properties: [String : AnyObject] = ["id": self.id,
                                                "title": self.title,
                                                "lastUpdated": self.lastUpdated,
                                                "count": self.count,
                                                "owner": self.owner,
                                                "topic": self.topic,
                                                "type": self.type]
        return properties
    }
    
    class func DocPropertiesToObj(doc: [String: AnyObject]) -> ScriptDoc? {

        let topic = doc["topic"] as! String
        let title = doc["title"] as! String
        let script = ScriptDoc.init(title: title, topic: topic)
        script.id = doc["id"] as! String
        script.lastUpdated = doc["lastUpdated"] as! String
        script.count = doc["count"] as! Int
        script.owner = doc["owner"] as! String
        script.topic = topic
        return script
    }


}

func GetTimestamp(since: String) -> String {
    if let tsInterval: NSTimeInterval = NSTimeInterval.init(since) {
        let today = moment()
        let tsMoment = moment(tsInterval)
        var timestamp = tsMoment.format("h:mm a")
        
        
        if (tsMoment.day == today.day) { // today
            if (today.hour - tsMoment.hour) < 7 {  // and within 7 hours
                timestamp = tsMoment.fromNow()
            }
        } else if ((tsMoment.day + 1) == today.day) { // yesterday
            timestamp = "yesterday"
        } else if (today.day - tsMoment.day) < 7 { // within 7 days
            timestamp = "\(tsMoment.weekdayName)"
        } else {  // long ago like 70 weeks
            timestamp = "\(tsMoment.month)/\(tsMoment.day)/\(tsMoment.year)"
        }
        
        return timestamp
    }
    return "just now"
}
