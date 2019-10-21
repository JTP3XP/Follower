//
//  TweetVideoTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 2/4/19.
//  Copyright © 2019 JohnPattonXP. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AVKit

class TweetVideoTableViewCell: TweetTableViewCell {

    @IBAction func playVideo(_ sender: UIButton) {
        guard let tweetVideoURLString = tweet?.video?.videoURL, let url = URL(string: tweetVideoURLString) else {
            return
        }
        
        delegate?.playVideo(fromURL: url)
        
    }

}
