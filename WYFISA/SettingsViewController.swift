//
//  SettingsViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class SettingsManager {
    // is singleton
    static let sharedInstance = SettingsManager()
    var nightMode: Bool = false
    var useFlash: Bool = false
}

let HEIGHT_FOR_HEADER:CGFloat = 30.0

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var navBar: UINavigationBar!
    @IBOutlet var settingsTable: UITableView!
    let settings = SettingsManager.sharedInstance
    let themer = WYFISATheme.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false

        // Do any additional setup after loading the view.
        self.settingsTable.dataSource = self
        self.settingsTable.delegate = self
        
        self.themeView()
    }
    
    func themeView(){
        self.navBar.barTintColor = self.themer.whiteForLightOrNavy(1.0)
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
    
    func cellForFontSection(row: Int) -> UITableViewCell {
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
                self.themer.setFont(newFont)
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
            label.text = "General"
        }
        if section == 1 {
            label.text = "Font"
        }
        label.font = ThemeFont.system(14, weight: UIFontWeightLight)
        view.addSubview(label)
        return view
    }

    // MARK: - targets
    func toggleNightMode(){
        self.settings.nightMode = !self.settings.nightMode
        if self.settings.nightMode == true {
            self.themer.setMode(Scheme.Dark)
        } else {
            self.themer.setMode(Scheme.Light)
        }
        self.themeView()
    }

    func toggleUseFlash(){
        self.settings.useFlash = !self.settings.useFlash
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
