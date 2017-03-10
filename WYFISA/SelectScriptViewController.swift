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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.scriptsTable.dataSource = self
        self.scriptsTable.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier("scriptcell")!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        Timing.runAfter(0.5){
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        self.performSegueWithIdentifier("showscriptsegue", sender: self)
    }
    
    
    @IBAction func unwindFromScriptView(segue: UIStoryboardSegue) {
        // MARK: - Navigation
    }
    
    @IBAction func unwindFromSettings(segue: UIStoryboardSegue) {
        // MARK: - Navigation
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return HIDE_STATUS_BAR
    }
    
    
    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
