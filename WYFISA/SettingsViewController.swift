//
//  SettingsViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

let HIDE_STATUS_BAR = false


class SettingsManager {
    // is singleton
    static let sharedInstance = SettingsManager()
    var nightMode: Bool = false
    var useFlash: Bool = false
    var version: Version = Version.ESV
    var owner: OwnerDoc
    var firstLaunch: Bool = false

    init(){
        
        // set owner as random
        self.owner = OwnerDoc()

        do {
            // open config db
            let db = try CBLManager.sharedInstance().databaseNamed(CONFIG_DB)
            
            // get settings
            if let doc = db.existingDocumentWithID("settings") {
                // restore settings
                self.nightMode = doc.propertyForKey("night") as! Bool
                if let versionProperty = doc.propertyForKey("version") as? Int {
                    self.version = Version(rawValue: versionProperty)!
                }
            }
            
            // get user info
            if let doc = db.existingDocumentWithID("owner") {

                // restore owner info
                self.owner.id = doc.propertyForKey("id") as! String
                if let ownerName = doc.propertyForKey("name") as? String {
                    self.owner.name = ownerName
                }
            } else {
                // create this owner doc
                let ownerDoc = db.documentWithID("owner")
                let properties = ["id": owner.id]
                try ownerDoc?.putProperties(properties)
            }

        } catch {
            print("error during config setup")
        }
        
        self.detectFirstLaunch()
    }
    
    func ownerId() -> String{
        return self.owner.id
    }
    
    func detectFirstLaunch(){
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.stringForKey("isAppAlreadyLaunchedOnce") == nil {
            self.firstLaunch = true
            defaults.setBool(true, forKey: "isAppAlreadyLaunchedOnce")
        }
    }
}

let HEIGHT_FOR_HEADER:CGFloat = 30.0

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var settingsTable: UITableView!
    let settings = SettingsManager.sharedInstance
    let themer = WYFISATheme.sharedInstance
    var settingsDoc: CBLDocument? = nil
    var lastFontSize: Float? = nil
    var lastFontType: ThemeFont? = nil
    var lastVersion: Version? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false

        // Do any additional setup after loading the view.
        self.settingsTable.dataSource = self
        self.settingsTable.delegate = self
        
        // style
        self.themeView()
        
        // settings db
        do {
            let db = try CBLManager.sharedInstance().databaseNamed(CONFIG_DB)
            if let doc = db.existingDocumentWithID("settings"){
                self.settingsDoc = doc
            } else {
                
                // create settings doc
                self.settingsDoc = db.documentWithID("settings")
                let properties = ["night": false,
                                  "flash": false,
                                  "font": themer.fontType.rawValue,
                                  "fontSize": themer.fontSize,
                                  "version": settings.version.rawValue]
                try self.settingsDoc?.putProperties(properties as! [String : AnyObject])
            }
            
        } catch { print("No db") }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // save any settings that have changed
        let currFontSize = Float(themer.fontSize)
        let currFontType = themer.fontType
        let currentVersion = settings.version
        
        if let old = self.lastFontSize {
            if old != currFontSize {
                self.updateSettings("fontSize", value: currFontSize)
            }
        }
        if let old = self.lastFontType {
            if old != currFontType {
                self.updateSettings("font", value: currFontType.rawValue)
            }
        }
        if let old = self.lastVersion {
            if old != currentVersion {
                self.updateSettings("version", value: currentVersion.rawValue)
            }
        }

        lastFontSize = currFontSize
        lastFontType = currFontType
        lastVersion = currentVersion
        self.settingsTable.reloadData()
        return
    }
    
    func themeView(){
        self.view.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.settingsTable.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.settingsTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellsubnav")!
        var label = cell.viewWithTag(1) as! UILabel

        switch indexPath.row {
        case 0:
            label.text = "Version"
            let currentLabel = cell.viewWithTag(2) as! UILabel
            let currentVersion = self.settings.version.text()
            currentLabel.text = currentVersion.uppercaseString
            
        case 1:
            label.text = "Font"
            let currentLabel = cell.viewWithTag(2) as! UILabel
            let currentFont = "\(self.themer.fontType.name()) \(Int(themer.fontSize))px"
            currentLabel.text = currentFont

        default:
            cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellchoice")!
            label = cell.viewWithTag(1) as! UILabel
            label.text = "Night Mode"
            let nightSwitch = cell.viewWithTag(2) as! UISwitch
            nightSwitch.addTarget(self, action:  #selector(self.toggleNightMode), forControlEvents: .ValueChanged)
            nightSwitch.setOn(settings.nightMode, animated: false)
        }

        // update theme
        cell.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        label.textColor = self.themer.navyForLightOrOffWhite(1.0)
        return cell

    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.row {
        case 0:
            self.performSegueWithIdentifier("versionsegue", sender: nil)
        default:
            self.performSegueWithIdentifier("fontsegue", sender: nil)
        }

    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    // MARK: - targets
    func toggleNightMode(){
        self.settings.nightMode = !self.settings.nightMode
        self.setNightMode(self.settings.nightMode)
        self.updateSettings("night", value: self.settings.nightMode)

    }

    func toggleUseFlash(){
        self.settings.useFlash = !self.settings.useFlash
        self.updateSettings("flash", value: self.settings.useFlash)

    }
    
    func setNightMode(on: Bool){
        if on == true {
            self.themer.setMode(Scheme.Dark)
        } else {
            self.themer.setMode(Scheme.Light)
        }
        self.themeView()
    }
    
    func updateSettings(_ key: String, value: AnyObject){
        do {
            try self.settingsDoc?.update({
                    (newRevision) -> Bool in
                    newRevision[key] = value
                    return true
                })
        } catch { print("update doc failed") }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return HIDE_STATUS_BAR
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return self.themer.statusBarStyle()
    }

}
