//
//  ScriptViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 12/5/16.
//  Copyright © 2016 RISE & RUN LLC. All rights reserved.
//

import UIKit

class ScriptViewController: UIViewController {

    var frameSize: CGSize!
    var navPrev = notifyCallback
    
    @IBOutlet var scriptCollection: ScriptCollection!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.view.frame.size = self.frameSize
        self.view.frame.size.height = self.frameSize.height*0.93
    }

    func configure(size: CGSize){
        self.frameSize = size
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func refresh(){
        self.scriptCollection.initDisplayVerses()
    }
    
    @IBAction func showScriptEditor(sender: AnyObject) {
        self.navPrev()
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
