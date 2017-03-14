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
    
    init(){
        do {
            let db = try CBLManager.sharedInstance().databaseNamed("config")
            if let doc = db.existingDocumentWithID("settings") {
                // restore settings
                self.nightMode = doc.propertyForKey("night") as! Bool
                self.useFlash = doc.propertyForKey("flash") as! Bool
                if let versionProperty = doc.propertyForKey("version") {
                    self.version = Version(rawValue: versionProperty as! Int)!
                }
            }
        } catch {}
        
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
            let db = try CBLManager.sharedInstance().databaseNamed("config")
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
    
    
    func cellForGeneralSection(row: Int) -> UITableViewCell {

        let cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellchoice")!
        let label = cell.viewWithTag(1) as! UILabel
        
        switch row {
        case 0:
            label.text = "Night Mode"
            let nightSwitch = cell.viewWithTag(2) as! UISwitch
            nightSwitch.addTarget(self, action:  #selector(self.toggleNightMode), forControlEvents: .ValueChanged)
            nightSwitch.setOn(settings.nightMode, animated: false)
        case 1:
            label.text = "Use Flash"
            let flashSwitch = cell.viewWithTag(2) as! UISwitch
            flashSwitch.addTarget(self, action:  #selector(self.toggleUseFlash), forControlEvents: .ValueChanged)
            flashSwitch.setOn(settings.useFlash, animated: false)
        default:
            (cell.viewWithTag(2) as! UISwitch).hidden = true
            label.text = nil
        }
        
        // theme
        cell.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        label.textColor = self.themer.navyForLightOrWhite(1.0)
 
        return cell
    }
    
    
    func fontSliderCell() -> UITableViewCell {
        // customize slider cell
        let cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellslider")!
        let label = cell.viewWithTag(1) as! UILabel
        let slider = cell.viewWithTag(2) as! UISlider

        // style
        let currentVal = Float(themer.fontSize)
        slider.value = currentVal
        label.text = "\(Int(currentVal))px"
        
        // theme
        cell.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        label.textColor = self.themer.navyForLightOrWhite(1.0)
        
        return cell
    }

    func cellForFontSection(row: Int) -> UITableViewCell {
        
        if row == 4 { // is slider
            return fontSliderCell()
        }
        
        let cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellselect")!
        let label = cell.viewWithTag(1) as! UILabel
        
        let font = ThemeFont(rawValue: row)
        label.text = font?.name()
        label.font = font?.styleWithSize(label.font.pointSize)
        
        if row == themer.fontType.rawValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        // theme
        cell.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        label.textColor = self.themer.navyForLightOrWhite(1.0)
        
        return cell
    }
    
    func cellForVersionSection(row: Int) -> UITableViewCell {

        let cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellselect")!
        let label = cell.viewWithTag(1) as! UILabel
        
        let version = Version(rawValue: row)
        label.text = version?.text()
        
        if row == self.settings.version.rawValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellsubnav")!
        switch indexPath.row {
        case 0:
            let label = cell.viewWithTag(1) as! UILabel
            label.text = "Version"
            
            let currentLabel = cell.viewWithTag(2) as! UILabel
            let currentVersion = self.settings.version.text()
            currentLabel.text = currentVersion.uppercaseString
            
        case 1:
            let label = cell.viewWithTag(1) as! UILabel
            label.text = "Font"
            
            let currentLabel = cell.viewWithTag(2) as! UILabel
            let currentFont = "\(self.themer.fontType.name()) \(Int(themer.fontSize))px"
            currentLabel.text = currentFont

        default:
            cell = self.settingsTable.dequeueReusableCellWithIdentifier("cellchoice")!
        }
        
        return cell
        /*
        switch indexPath.section {
        case 0:
            return cellForVersionSection(indexPath.row)
        case 2:
            return cellForFontSection(indexPath.row)
        default:
            return cellForGeneralSection(indexPath.row)
        }
        */

    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.row {
        case 0:
            self.performSegueWithIdentifier("versionsegue", sender: nil)
        default:
            self.performSegueWithIdentifier("fontsegue", sender: nil)
        }

        /*
        if indexPath.section == 1 {  // selected a font
            if let newFont = ThemeFont(rawValue: indexPath.row) {
                self.themer.setFontStyle(newFont)
                self.updateSettings("font", value: indexPath.row)
            }
        }
        
        // update view
        tableView.reloadData()
        */
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
       // return HEIGHT_FOR_HEADER
    }
    
    /*
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = themer.offWhiteForLightOrNavy(0.1)
        let label = UILabel(frame: CGRectMake(10, 0, tableView.frame.width, HEIGHT_FOR_HEADER))
        if section == 0 {
            label.text = "Version"
        }
        if section == 1 {
            label.text = "Lighting"
        }
        if section == 2 {
            label.text = "Font"
        }
        label.font = ThemeFont.system(14, weight: UIFontWeightLight)
        label.textColor = themer.navyForLightOrOffWhite(0.8)
        view.addSubview(label)
        return view
    }
    */

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
    
    @IBAction func didChangeFontSizeSlider(sender: UISlider) {
        let value = CGFloat(sender.value)
        self.themer.setFontSize(value)
        let path = NSIndexPath.init(forRow: 4, inSection: 1)
        self.settingsTable.reloadRowsAtIndexPaths([path], withRowAnimation: .None)
        self.updateSettings("fontSize", value: value)

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
    


}
