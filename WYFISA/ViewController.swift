//
//  ViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var verseTable: UITableView!
    @IBOutlet var filterView: GPUImageView!
    let stillCamera = CameraManager()
    var nVerses = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // send camera to live view
        self.filterView.fillMode = GPUImageFillModeType.init(2)
        self.stillCamera.addCameraTarget(self.filterView)
        
        // camera config
        stillCamera.zoom(1.5)
        stillCamera.focus()
        
        // start capture
        stillCamera.capture()

        // setup tableview
        self.verseTable.delegate = self
        self.verseTable.dataSource = self
    }
    
    
    @IBAction func addRowForVerse(sender: AnyObject) {
        
        // adds row to verse table
        self.nVerses = self.nVerses + 1

        // when table is reloaded new cells well container OCR data
        self.verseTable.reloadData()
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("verseCell"){
            if indexPath.section == self.nVerses-1 {
                // this is last verse so we need to trigger ocr event
                if let view = cell.viewWithTag(1) {
                    let label = view as! UILabel
                    let event = CaptureHandler(label: label, camera: self.stillCamera)
                    event.recognizeFrameFromCamera()
                }
                cell.layer.cornerRadius = 2
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.nVerses
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        view.tintColor = UIColor.clearColor()
    }
    
}

