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
    var inReaderMode = false
    var scriptId: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func configure(size: CGSize){
        self.frameSize = size
    }
    
    // MARK: -Show/Hide
    func didPressReaderButton(){
        
        self.inReaderMode = !self.inReaderMode
        self.view.frame.size = self.frameSize
        self.scriptCollection.initDisplayVerses(self.scriptId!)
        self.scriptCollection.scrollEnabled = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    


    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

    }

}
