//
//  FontSettingsViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/13/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

class FontSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    @IBOutlet var fontTable: UITableView!
    let themer = WYFISATheme.sharedInstance

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fontTable.dataSource = self
        self.fontTable.delegate = self
        self.themeView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func fontSliderCell() -> UITableViewCell {
        // customize slider cell
        let cell = self.fontTable.dequeueReusableCellWithIdentifier("cellslider")!
        let label = cell.viewWithTag(1) as! UILabel
        let slider = cell.viewWithTag(2) as! UISlider
        
        // style
        let currentVal = Float(themer.fontSize)
        slider.value = currentVal
        label.text = "\(Int(currentVal))px"
        
        // theme
        label.textColor = self.themer.navyForLightOrOffWhite(1.0)
        
        return cell
    }
    

    func cellForFontSection(row: Int) -> UITableViewCell {
        
        if row == 4 { // is slider
            return fontSliderCell()
        }
        
        let cell = self.fontTable.dequeueReusableCellWithIdentifier("cellselect")!
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
        return cellForFontSection(indexPath.row)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let newFont = ThemeFont(rawValue: indexPath.row) {
            self.themer.setFontStyle(newFont)
        }
        self.fontTable.reloadData()
    }
    
    @IBAction func didChangeFontSizeSlider(sender: UISlider) {
        let value = CGFloat(sender.value)
        self.themer.setFontSize(value)
        let path = NSIndexPath.init(forRow: 4, inSection: 0)
        self.fontTable.reloadRowsAtIndexPaths([path], withRowAnimation: .None)
        
    }
    
    // MARK: - Theme
    func themeView(){
        self.view.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.fontTable.backgroundColor = self.themer.whiteForLightOrNavy(1.0)
        self.fontTable.reloadData()
    }
    
}
