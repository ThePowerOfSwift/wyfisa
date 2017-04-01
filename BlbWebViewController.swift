//
//  BlbWebViewController.swift
//  WYFISA
//
//  Created by Tommie McAfee on 3/28/17.
//  Copyright © 2017 RISE & RUN LLC. All rights reserved.
//

import UIKit
import WebKit

class BlbWebViewController: UIViewController, WKUIDelegate {
    var webView: WKWebView!
    
    override func loadView() {
        super.loadView()
        // webview
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero,
                            configuration: webConfiguration)
        webView.UIDelegate = self
        view = webView
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup webview
        let url = NSURL(string: "https://www.blueletterbible.org/lang/lexicon/lexicon.cfm?t=kjv&strongs=g26")
        let request = NSURLRequest(URL: url!)
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
