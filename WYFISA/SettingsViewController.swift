//
//  SettingsViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

let HIDE_STATUS_BAR = false

enum Version: Int {
    case KJV = 0, ESV, NIV, NLT
    func text() -> String {
        switch self{
        case .KJV:
            return "kjv"
        case .ESV:
            return "esv"
        case .NIV:
            return "niv"
        case .NLT:
            return "nlt"
        }
    }
}

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
                // TODO self.version = doc.propertyForKey("version") as! Bool
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
                                  "fontSize": themer.fontSize]
                try self.settingsDoc?.putProperties(properties as! [String : AnyObject])
            }
            
        } catch { print("No db") }
        
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 1:
            return cellForFontSection(indexPath.row)
        default:
            return cellForGeneralSection(indexPath.row)
        }

    }
    

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 1 {  // selected a font
            if let newFont = ThemeFont(rawValue: indexPath.row) {
                self.themer.setFontStyle(newFont)
                self.updateSettings("font", value: indexPath.row)
            }
        }
        
        // update view
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1: // font section
            return 5
        default: // general section
            return 2
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return HEIGHT_FOR_HEADER
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = themer.offWhiteForLightOrNavy(0.1)
        let label = UILabel(frame: CGRectMake(10, 0, tableView.frame.width, HEIGHT_FOR_HEADER))
        if section == 0 {
            label.text = "Lighting"
        }
        if section == 1 {
            label.text = "Font"
        }
        label.font = ThemeFont.system(14, weight: UIFontWeightLight)
        label.textColor = themer.navyForLightOrOffWhite(0.8)
        view.addSubview(label)
        return view
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
