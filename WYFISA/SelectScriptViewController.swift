//
//  SelectScriptViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/10/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit


class SelectScriptViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var addScriptButton: UIButton!
    @IBOutlet var scriptsTable: UITableView!
    @IBOutlet var scriptTitle: UILabel!
    var storage: CBStorage = CBStorage(databaseName: SCRIPTS_DB)
    var selectedScript: ScriptDoc? = nil
    var activeTopic: TopicDoc? = nil
    var myScripts: [ScriptDoc] = []
    var highlightedIndexPath: NSIndexPath? = nil
    let themer = WYFISATheme.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.scriptsTable.dataSource = self
        self.scriptsTable.delegate = self

        // theme
        self.themeView()

    }

    override func viewWillAppear(animated: Bool) {
        self.getScriptsForTopic()
        self.scriptsTable.reloadData()

    }
    
    override func viewDidAppear(animated: Bool) {
        // self.selectedScript = self.myScripts[0]
       // self.performSegueWithIdentifier("showscriptsegue", sender: self)
    }
    
    func getScriptsForTopic(){
        // show last viewed topic or recently selected topic
        if self.activeTopic == nil {
            let ownerId = SettingsManager.sharedInstance.ownerId()
            if let topic = storage.getRecentTopic(ownerId) {
                self.activeTopic = topic
            } else { // no topics!
                self.activeTopic = TopicDoc.init(owner: ownerId)
                self.activeTopic?.title = "New Topic"
                self.storage.putTopic(self.activeTopic!)
            }
        }
        self.myScripts = storage.getScriptsForTopic(self.activeTopic!.id)
        self.scriptTitle.text = self.activeTopic!.title
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
        let ts = GetTimestamp(script.lastUpdated)
        scriptTimestampLabel.text = "\(ts)"
        
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
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            
            // handle delete action
            tableView.editing = false
            let row = indexPath.row
            let script = self.myScripts[row]
            self.storage.deleteScript(script)
            self.myScripts.removeAtIndex(row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
        return [deleteAction]
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath?) {
        // do something if you want
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
    
    override func prefersStatusBarHidden() -> Bool {
        return HIDE_STATUS_BAR
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return self.themer.statusBarStyle()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // creating a script
        if segue.identifier == "addscriptsegue" {
            if let initVC = segue.destinationViewController as? InitViewController {
                
                // create new script
                let script = ScriptDoc.init(title: DEFAULT_SCRIPT_NAME,
                                             topic: self.activeTopic!.id)
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
        //self.addScriptButton.layer.borderColor = UIColor.darkGrayColor().CGColor
        //self.addScriptButton.layer.borderWidth = 3.0

        self.scriptsTable.reloadData()
    }
}
