//
//  UserScript.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/11/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit
import SwiftMoment

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

    func getTimestamp() -> String {
        if let tsInterval: NSTimeInterval = NSTimeInterval.init(self.lastUpdated) {
            let today = moment()
            let tsMoment = moment(tsInterval)
            var timestamp = tsMoment.format("h:mm a")
            

            if (tsMoment.day == today.day) { // today
                if (tsMoment.hour - today.hour) < 7 {  // and within 7 hours
                    timestamp = tsMoment.fromNow()
                }
            } else if ((tsMoment.day + 1) == today.day) { // yesterday
                timestamp = "yesterday"
            } else if (tsMoment.day - today.day) < 7 { // within 7 days
                timestamp = "\(tsMoment.weekdayName)"
            } else {  // long ago like 70 weeks
                timestamp = "\(tsMoment.month)/\(tsMoment.day)/\(tsMoment.year)"
            }
            
            return timestamp
        }
        return "just now"
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
