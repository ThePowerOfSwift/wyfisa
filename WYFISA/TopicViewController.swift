//
//  TopicViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/11/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

class TopicViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet var topicTable: UITableView!
    
    let themer = WYFISATheme.sharedInstance
    var storage: CBStorage = CBStorage(databaseName: SCRIPTS_DB)
    var topics = [TopicDoc]()
    var ownerId: String? = nil
    var newTopicTextField: UITextField? = nil
    var selectedTopic: TopicDoc? = nil
    var oldTitle: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.topicTable.dataSource = self
        self.topicTable.delegate = self

        self.ownerId = SettingsManager.sharedInstance.ownerId()

        // apply theme
        self.themeView()

    }
    
    override func viewWillAppear(animated: Bool) {
        self.topics = storage.getTopicsForOwner(self.ownerId!)
        self.topicTable.reloadData()
        
        // detect first launch
        if SettingsManager.sharedInstance.firstLaunch == true {
           SettingsManager.sharedInstance.firstLaunch = false
            // segue to getting started script
            if self.topics.count == 1 {
                self.selectedTopic = self.topics[0]
                self.performSegueWithIdentifier("selectscriptsegue", sender: self)
            }

        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topics.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("topiccell")!
        let topic = self.topics[indexPath.row]
        if topic.title == nil {
            cell = tableView.dequeueReusableCellWithIdentifier("newtopiccell")!
            let textField = cell.viewWithTag(1) as! UITextField
            textField.text = nil
            textField.delegate = self
            textField.textColor = themer.navyForLightOrOffWhite(1.0)
            if let oldTitle = self.oldTitle {
                textField.placeholder = oldTitle
                self.oldTitle = nil
            }
            self.newTopicTextField = textField
        } else {
            let label = cell.viewWithTag(1) as! UILabel
            label.textColor = themer.navyForLightOrOffWhite(1.0)
            label.text = topic.title
            let countLabel = cell.viewWithTag(2) as! UILabel
            countLabel.textColor = themer.navyForLightOrOffWhite(1.0)
            if topic.count > 0 {
                countLabel.text = "\(topic.count)"
                countLabel.hidden = false
            } else {
                countLabel.hidden = true
            }
        }

        // allow editing new topic
        if indexPath.row == (tableView.numberOfRowsInSection(indexPath.section) - 1){
            self.newTopicTextField?.becomeFirstResponder()
        }
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil  // todo sync info
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let row = indexPath.row
        
        let editAction = UITableViewRowAction(style: .Normal, title: "Edit") { (action, indexPath) -> Void in
            
            // handle edit action
            tableView.editing = false
            self.oldTitle = self.topics[row].title
            self.topics[row].title = nil
            tableView.reloadData()
        }
        editAction.backgroundColor = UIColor.grayColor()
        
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete") { (action, indexPath) -> Void in
            
            // handle delete action
            tableView.editing = false
            let topic = self.topics[row]
            self.storage.deleteTopic(topic)
            self.topics.removeAtIndex(row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        
        return [deleteAction, editAction]
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath?) {
        // do something if you want
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleAddTopic(sender: AnyObject) {
        
    }

    @IBAction func addNewTopic(sender: AnyObject) {
        if self.newTopicTextField != nil {
            return  // already editing
        }
        let topic = TopicDoc.init(owner: self.ownerId!)
        self.topics.insert(topic, atIndex: 0)
        self.topicTable.reloadData()

    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        self.selectedTopic = self.topics[indexPath.row]
        return indexPath
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("selectscriptsegue", sender: self)
    }
    
    // MARK: - TextField Delegate
    func textFieldDidEndEditing(textField: UITextField) {

        // save topic title
        if self.newTopicTextField?.text == nil || self.newTopicTextField?.text == "" {
            self.newTopicTextField = nil
            return // title required
        }
        let title = self.newTopicTextField?.text
        let topic = self.topics[0]
        topic.title = title
        self.storage.putTopic(topic)
        
        // cleanup
        self.newTopicTextField?.delegate = nil
        self.newTopicTextField = nil
        
        // reload
        let path = NSIndexPath(forRow: 0, inSection: 0)
        self.topicTable.reloadRowsAtIndexPaths([path], withRowAnimation: .Automatic)
        
        self.selectedTopic = topic
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.newTopicTextField?.resignFirstResponder()
        return true
    }

    // MARK: - Navigation
    @IBAction func unwindFromSettings(segue: UIStoryboardSegue) {
        // MARK: - Navigation
        self.themeView()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destVC = segue.destinationViewController as? SelectScriptViewController {
            destVC.activeTopic = self.selectedTopic
        }
    }
    // MARK: - Theme
    func themeView(){
        self.view.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.topicTable.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.topicTable.reloadData()
    }

}
