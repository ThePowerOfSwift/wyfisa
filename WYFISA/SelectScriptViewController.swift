//
//  SelectScriptViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/10/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit


class SelectScriptViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var scriptsTable: UITableView!
    var storage: CBStorage = CBStorage(databaseName: SCRIPTS_DB)
    var selectedScript: UserScript? = nil
    var selectedTopicId: String = "alpha"
    var myScripts: [UserScript] = []
    var highlightedIndexPath: NSIndexPath? = nil
    let themer = WYFISATheme.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.scriptsTable.dataSource = self
        self.scriptsTable.delegate = self
        
        self.myScripts = storage.getScriptsForTopic(self.selectedTopicId)
        
        self.themeView()
        
    }

    override func viewWillAppear(animated: Bool) {
        self.myScripts = storage.getScriptsForTopic(self.selectedTopicId)
        self.scriptsTable.reloadData()

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myScripts.count
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let script = self.myScripts[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("scriptcell")!
        
        // title
        let scriptNameLabel = cell.viewWithTag(1) as! UILabel
        if script.title.length > 0 {
            scriptNameLabel.text = script.title
        } else {
            scriptNameLabel.text = DEFAULT_SCRIPT_NAME
        }
        
        // ts
        let scriptTimestampLabel = cell.viewWithTag(2) as! UILabel
        scriptTimestampLabel.text = "\(script.getTimestamp())"
        
        // count
        let scriptVerseCountLabel = cell.viewWithTag(3) as! UILabel
        scriptVerseCountLabel.text = "\(script.count)"
        
        // theme
        scriptNameLabel.textColor = themer.navyForLightOrOffWhite(1.0)
        scriptVerseCountLabel.textColor = themer.navyForLightOrOffWhite(1.0)
        scriptTimestampLabel.textColor = themer.navyForLightOrOffWhite(1.0)
        cell.selectedBackgroundView = themer.greyViewForLightOrTurquoise()
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        Timing.runAfter(0.5){
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        let script = self.myScripts[indexPath.row]
        self.selectedScript = script
        self.performSegueWithIdentifier("showscriptsegue", sender: self)
    }

    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        self.highlightedIndexPath = indexPath
    }
    
    
    @IBAction func unwindFromReaderView(segue: UIStoryboardSegue) {
        // MARK: - Navigation
    }
    
    @IBAction func unwindFromTopicView(segue: UIStoryboardSegue) {
        // MARK: - Navigation
    }
    
    
    @IBAction func unwindFromScriptView(segue: UIStoryboardSegue) {
        // MARK: - Navigation
    }
    
    @IBAction func unwindFromSettings(segue: UIStoryboardSegue) {
        // MARK: - Navigation
        self.themeView()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return HIDE_STATUS_BAR
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // creating a script
        if segue.identifier == "addscriptsegue" {
            if let initVC = segue.destinationViewController as? InitViewController {
                
                // create new script
                let script = UserScript.init(title: DEFAULT_SCRIPT_NAME,
                                             topic: self.selectedTopicId)
                // store into db
                storage.putScript(script)
                
                // add to data source
                self.myScripts.append(script)
                
                let newScriptId = script.id
                initVC.activeScriptId = newScriptId
                initVC.isNewScript = true

            }
        }
        
        // showing a script
        if segue.identifier == "showscriptsegue" {
            if let initVC = segue.destinationViewController as? InitViewController {
                initVC.activeScriptId = self.selectedScript!.id
            }
        }
        
        if segue.identifier == "zensegue" {
            if let readerVC = segue.destinationViewController as? ScriptViewController {
                readerVC.prepareForScript(self.selectedScript!.id, title: self.selectedScript!.title)
            }
        }
    }
    
    
    @IBAction func enterZenMode(sender: UILongPressGestureRecognizer) {
        if let indexPath = self.highlightedIndexPath {
            self.highlightedIndexPath = nil
            self.selectedScript = self.myScripts[indexPath.row]
            self.performSegueWithIdentifier("zensegue", sender: nil)
        }
    }
    
    // MARK: - Theme
    func themeView(){
        self.view.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.scriptsTable.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.scriptsTable.reloadData()
    }
}
