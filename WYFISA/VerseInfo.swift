//
//  VerseInfo.swift
//  WYFISA
//
//  Created by Tommie McAfee on 11/28/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import Foundation


enum ItemCategory: Int {
    
    case Verse = 0, Note, Image
    
    func name() -> String {
        switch self.rawValue {
        case 0:
            return "Avenir"
        case 1:
            return "Baskerville"
        case 2:
            return "Iowan"
        default:
            return "San Francisco"
        }
    }
    
}

class VerseInfo {
    let id: String
    var name: String
    var priority: Float = -1.0
    var session: UInt64 = 0
    var text: String?
    var chapter: String?
    var chapterNo: Int?
    var bookNo: Int?
    var verse: Int?
    var image: UIImage?
    var overlayImage: UIImage?
    var accessoryImage: UIImage?
    var refs: [VerseInfo]?
    var verses: [VerseInfo]?
    var category: ItemCategory = .Verse
    
    init(id: String, name: String, text: String?){
        self.id = id
        self.name = name
        self.text = text
    }
}
