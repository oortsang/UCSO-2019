//
//  ThirdViewController.swift
//  UCSO Invitational 2018
//
//  Created by Jung-Sun Yi-Tsang on 12/10/17.
//  Copyright © 2017 bayser. All rights reserved.
//

import Foundation
import WebKit

class ThirdViewController: UIViewController {
    
    @IBOutlet weak var webview: WKWebView!
    @IBAction func backFunc(_ sender: Any) {
        webview.goBack()
    }
    
    @IBAction func forwardFunc(_ sender: Any) {
        webview.goForward()
    }
    
    @IBAction func refreshFunc(_ sender: Any) {
        webview.reload()
    }
    
    @IBAction func ezraFunc(_ sender: Any) {
        let url = URL(string: "https://www.ezratech.us/competition/illinois-state-tournament-division-c")
        let request = URLRequest(url: url!)
        webview.load(request)
    }
    
    @IBAction func ucsoFunc(_ sender: Any) {
        let url = URL(string: "https://uchicagoscio.com/")
        let request = URLRequest(url: url!)
        webview.load(request)
    }
    
    @IBAction func shareFunc(_ sender: Any) {
        guard webview.url != nil else {
            return
        }
        UIApplication.shared.open(webview.url!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "http://www.illinoisolympiad.org/state.html")
        let request = URLRequest(url: url!)
        webview.load(request)
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
