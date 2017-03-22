//
//  VersionSettingsViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/13/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

class VersionSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    @IBOutlet var versionTable: UITableView!
    let settings = SettingsManager.sharedInstance
    let themer = WYFISATheme.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        self.versionTable.dataSource = self
        self.versionTable.delegate = self
        self.themeView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.versionTable.dequeueReusableCellWithIdentifier("cellselect")!
        let label = cell.viewWithTag(1) as! UILabel
        
        let row = indexPath.row
        let version = Version(rawValue: row)
        label.text = version?.desc()
        
        if row == self.settings.version.rawValue {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        
        label.textColor = self.themer.navyForLightOrOffWhite(1.0)
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let newVersion = Version(rawValue: indexPath.row){
            self.settings.version = newVersion
        }
        self.versionTable.reloadData()
    }

    // MARK: - Theme
    func themeView(){
        self.view.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.versionTable.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.versionTable.reloadData()
    }
    

}
