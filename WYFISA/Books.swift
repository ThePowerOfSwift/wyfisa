//
//  Books.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/23/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import Foundation

struct BooksData {
    var data: [[String:AnyObject]]
    static let sharedInstance = BooksData()

    init(){
        self.data = [[String:AnyObject]]()
        let filePath = NSBundle.mainBundle().pathForResource("books",ofType:"json")
        if let jsonData = NSData.init(contentsOfFile: filePath!) {
            do {
                let jsonDict = try NSJSONSerialization.JSONObjectWithData(jsonData, options: .AllowFragments)
                self.data = jsonDict as! [[String:AnyObject]]
            } catch  let err {
                print(err, "json load error")
            }
            
        }
    }
}


enum Books: Int {
    
    case Gen = 1,Ex,Lev,Num,Deut,Josh,Judg,Ruth,Sam1,Sam2,Kings1,Kings2,Chr1,Chr2,Ezra,Neh,Esth,Job,Ps,Prov,Ecc,Song,Isa,Jer,Lam,Ezek,Dan,Hos,Joel,Am,Ob,Jon,Mic,Nah,Hab,Zeph,Hag,Zech,Mal,Mt,Mk,Lk,Jn,Acts,Rom,Cor1,Cor2,Gal,Eph,Phil,Col,Thess1,Thess2,Tim1,Tim2,Titus,Philemon,Heb,Jas,Pet1,Pet2,Jn1,Jn2,Jn3,Jude,Rev
    
    func name() -> String {
        let data = BooksData.sharedInstance.data
        let bookName = data[self.rawValue-1]["n"] as! String
        return bookName
    }
}
