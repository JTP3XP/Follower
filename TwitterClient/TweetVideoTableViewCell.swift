//
//  TweetVideoTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 2/4/19.
//  Copyright © 2019 JohnPattonXP. All rights reserved.
//

import UIKit
import WebKit

class TweetVideoTableViewCell: TweetTableViewCell {

    @IBOutlet weak var videoWebView: WKWebView!
    
    override func updateUI() {
        super.updateUI()
        
        fullNameLabel.textColor = #colorLiteral(red: 0.8208763003, green: 0.1303744018, blue: 0.2447820008, alpha: 1)
        
    }

    @IBAction func pressedPlay(_ sender: UIButton) {
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        let webView = WKWebView(frame: videoWebView.frame, configuration: configuration)
        self.addSubview(webView)
        
        if let videoURL:URL = URL(string: "https://video.twimg.com/ext_tw_video/1095890409048264704/pu/vid/720x1280/Mf4zUxt944X3bkoP.mp4?tag=6") {
            let request:URLRequest = URLRequest(url: videoURL)
            webView.load(request)
        }
    }
}
