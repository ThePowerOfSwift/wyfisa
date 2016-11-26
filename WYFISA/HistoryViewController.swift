//
//  HistoryViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 10/22/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet var verseTable: VerseTableView!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var clearAllButton: UIButton!
    
    var tableDataSource: VerseTableDataSource? = nil
    var frameSize: CGSize? = nil
    var isEditingMode: Bool = false
    
    func configure(dataSource: VerseTableDataSource, isExpanded: Bool, size: CGSize){
        self.tableDataSource = dataSource
        self.view.frame.size = size
        self.frameSize = size
    }
    
    override func viewDidAppear(animated: Bool) {
        self.verseTable.dataSource = self.tableDataSource
        self.verseTable.isExpanded = true
        if let size = self.frameSize {
            self.view.frame.size = size
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateIconsForEditingMode(mode: Bool){
        var fireButton: UIImage? = nil
        if mode == true {
            // entering editing mode
            fireButton = UIImage.init(named: "ios7-minus-fire")
            Animations.start(0.3){
                self.clearAllButton.alpha = 1
            }
        } else {
            fireButton = UIImage.init(named: "ios7-minus")
            Animations.start(0.3){
                self.clearAllButton.alpha = 0
            }
        }
        self.clearButton.setImage(fireButton, forState: .Normal)
    }
    
    @IBAction func didPressClearButton(sender: AnyObject) {
        
        // toggle editing mode
        self.isEditingMode = !self.isEditingMode
        self.updateIconsForEditingMode(self.isEditingMode)

        // update editing state
        self.verseTable.setEditing(self.isEditingMode, animated: true)
    }
    
    @IBAction func didPressClearAllButton(sender: AnyObject) {
        self.isEditingMode = false
        self.verseTable.setEditing(self.isEditingMode, animated: true)
        
        // empty table
        self.verseTable.clear()
        self.updateIconsForEditingMode(false)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
