//
//  SettingsViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 9/16/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var settingsTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false

        // Do any additional setup after loading the view.
        self.settingsTable.dataSource = self
        self.settingsTable.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        if indexPath.row < 2 {
            cell = tableView.dequeueReusableCellWithIdentifier("cellsubnav")!
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("cellchoice")!
        }
        
        let label = cell.viewWithTag(1) as! UILabel

        switch indexPath.row {
        case 0:
            label.text = "Version"
            let detail = cell.viewWithTag(2) as! UILabel
            detail.text = "ASV"
        case 1:
            label.text = "Font"
            let detail = cell.viewWithTag(2) as! UILabel
            detail.text = "Iowan"
        case 2:
            label.text = "Night Mode"
        case 3:
            label.text = "Use Flash"
        default:
            (cell.viewWithTag(2) as! UISwitch).hidden = true
            label.text = nil
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
