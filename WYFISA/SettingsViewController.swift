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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("cellchoice")!

        
        let label = cell.viewWithTag(1) as! UILabel

        switch indexPath.row {
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
        return 10.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var view = UIView()
        view.backgroundColor = themer.offWhiteForLightOrNavy(0.1)
        return view
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    // MARK: - UITableView Delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            self.performSegueWithIdentifier("versionsegue", sender: self)
        }
        if indexPath.row == 1 {
            self.performSegueWithIdentifier("fontsegue", sender: self)
        }
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
