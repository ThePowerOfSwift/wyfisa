//
//  TopicViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/11/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit

class TopicViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var topicTable: UITableView!
    let themer = WYFISATheme.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.topicTable.dataSource = self
        self.topicTable.delegate = self
        
        // apply theme
        self.themeView()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("topiccell")!
        let label = cell.viewWithTag(1) as! UILabel
        label.textColor = themer.navyForLightOrOffWhite(1.0)
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func handleAddTopic(sender: AnyObject) {
        
    }

    // MARK: - Theme
    func themeView(){
        self.view.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.topicTable.backgroundColor = self.themer.tanForLightOrNavy(1.0)
        self.topicTable.reloadData()
    }

}
