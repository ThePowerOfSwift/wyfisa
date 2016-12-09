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
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.scriptCollection.initDisplayVerses()
    }
    



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func refresh(){
        self.scriptCollection.initDisplayVerses()
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
