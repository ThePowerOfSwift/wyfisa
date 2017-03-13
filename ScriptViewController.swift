//
//  ScriptViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 12/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class ScriptViewController: UIViewController {

    @IBOutlet var scriptCollection: ScriptCollection!
    var frameSize = CGSize()
    var scriptId: String? = nil
    var scriptTitle: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.scriptCollection.initDisplayVerses(self.scriptId!)
        self.scriptCollection.scrollEnabled = true
    }
    func prepareForScript(scriptId: String, title: String){
        self.scriptId = scriptId
        self.scriptTitle = title
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return HIDE_STATUS_BAR
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }
    @IBAction func exitReaderMode(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
