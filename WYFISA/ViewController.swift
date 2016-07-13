//
//  ViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 7/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CaptureHandlerDelegate {

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
        let idxSet = NSIndexSet(index: 0)
        self.verseTable.insertSections(idxSet, withRowAnimation: .Fade)
        
        // capture while row is being added
        let event = CaptureHandler(id: self.nVerses, camera: self.stillCamera)
        event.delegate = self
        event.recognizeFrameFromCamera()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("verseCell"){
            cell.layer.cornerRadius = 2
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
    
    func didProcessFrame(sender: CaptureHandler, withText text: String, forId id: Int) {
        let index = id - self.nVerses
        print("GOT \(id) For \(index)")
        print(text)

        let indexPath = NSIndexPath(forRow: 0, inSection: index)
        if let cell = self.verseTable.cellForRowAtIndexPath(indexPath){
            if let view = cell.viewWithTag(1) {
                let label = view as! UILabel
                label.text = text
                print("SET LABEL", label.text)
            }
            self.verseTable.reloadSections(NSIndexSet(index: index), withRowAnimation: .Fade)
        }
    }
    
}

