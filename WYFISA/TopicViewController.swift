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
    var editingRow: Int = -1
    var quickCaptureVC: CaptureViewController!
    var cam = SharedCameraManager.instance

    @IBOutlet var disabledCamView: UIView!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var quickCaptureContainerView: UIView!
    @IBOutlet var quickCaptureButton: UIButton!
    @IBOutlet var searchView: UIView!
    @IBOutlet var escapeImageMask: UIImageView!
    @IBOutlet var escapeMask: UIView!
    @IBOutlet var searchBar: UISearchBar!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.topicTable.dataSource = self
        self.topicTable.delegate = self

        self.ownerId = SettingsManager.sharedInstance.ownerId()

        // apply theme
        self.themeView()
        
        self.doneButton.hidden = true

    }
    
    override func viewWillAppear(animated: Bool) {

        self.searchView?.alpha = 0
        if !self.themer.isLight() {
            self.escapeImageMask.image = UIImage.init(named: "Gradient-navy")
        }
        
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
            self.editingRow = row
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
        self.editingRow = 0
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
        let title = textField.text
        let topic = self.topics[self.editingRow]
        topic.title = title
        self.storage.putTopic(topic)
        
        // cleanup
        self.newTopicTextField?.delegate = nil
        self.newTopicTextField = nil
        
        // reload
        let path = NSIndexPath(forRow: self.editingRow, inSection: 0)
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
        if let destVC = segue.destinationViewController as? SearchBarViewController {
            destVC.escapeImageMask = self.escapeImageMask
            destVC.escapeMask = self.escapeMask
            destVC.searchView = self.searchView
            destVC.originalFrameSize = self.view.frame.size
            destVC.originalFrameSize.height = destVC.originalFrameSize.height*1.2
            destVC.unwindIdentifier = "quickresultsegue"
            self.searchBar.delegate = destVC
        }
        if let destVC = segue.destinationViewController as? CaptureViewController {
            self.quickCaptureVC = destVC
            self.quickCaptureVC.configure(self.view.frame.size)
            self.quickCaptureContainerView.hidden = true
        }
    }
    
    @IBAction func didTapToEndSearch(sender: AnyObject) {
        self.searchBar.endEditing(true)
        Animations.start(0.3){
            self.escapeImageMask.hidden = true
            self.escapeMask.hidden = true
        }
    }
    
    @IBAction func didPressQuickCaptureButton(sender: AnyObject) {
        if self.cam.checkCameraAuth() == false {
            // user has not authorized use of camera
            
            if self.cam.didAuthCameraUsage() == true {
                // this is not the first time we've asked for auth
                // so put up a privacy window
                self.disabledCamView.hidden = false
                
            } else {
                // record that we've asked for camera permission
                self.cam.setCameraAuthStatus()
            }
            
            return
        } else if self.cam.didAuthCameraUsage() == false {
            // upgrade scenario where user has authorized use of camera
            // but the property hasn't been set
            self.cam.setCameraAuthStatus()
            self.cam.prepareCamera()
           // self.prepareCamUsage()
        }
        
        if self.cam.ready == false {
            // camera is not ready
            return
        }
        Animations.start(0.3){
            self.quickCaptureContainerView.alpha = 1
            self.quickCaptureContainerView.hidden = false
        }
        CaptureSession.sharedInstance.clearMatches()
        self.quickCaptureVC.didPressCaptureButton()

    }
    
    @IBAction func didReleaseQuickCaptureButton(sender: AnyObject) {
        let newMatches = self.quickCaptureVC.didReleaseQuickCaptureButton()
        if newMatches == true {
            self.doneButton.hidden = false
            self.quickCaptureButton.hidden = true
        } else {
            self.didPressDoneButton(self)
        }
        self.disabledCamView.hidden = true
    }
    
    @IBAction func didPressDoneButton(sender: AnyObject) {
        self.quickCaptureVC.didReleaseCaptureButton()
        Animations.start(0.3){
            self.quickCaptureContainerView.alpha = 0
        }
        Timing.runAfter(0.3){
            self.quickCaptureContainerView.hidden = true
        }
        self.doneButton.hidden = true
        self.quickCaptureButton.hidden = false
    }
    
    // MARK: - Theme
    func themeView(){
        self.view.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.topicTable.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.topicTable.reloadData()
    }

}
