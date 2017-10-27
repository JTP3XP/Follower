//
//  TweetLinkTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 9/24/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit

class TweetLinkTableViewCell: TweetTableViewCell {

    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardSubtitleLabel: UILabel!
    
    override func updateUI() {
        super.updateUI()
        
        // Set card title
        cardTitleLabel.text = tweet?.card?.title ?? "Link"
        
        // Set card subtitle
        cardSubtitleLabel.text = tweet?.card?.relatedTweetURL?.urlString ?? ""
        
        // Set link picture
        if let linkImageURL = tweet?.card?.imageURL {
            let lastLinkImageURL = linkImageURL // store the URL so we can check if it is still the same before we update UI on main thread
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: URL(string: linkImageURL)!) {
                    DispatchQueue.main.async { [weak self] in
                        if linkImageURL == lastLinkImageURL { // make sure we aren't coming back to a cell that got reused for another tweet before displaying result
                            self?.cardImageView.image = UIImage(data: imageData)
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.cardImageView.image = nil
                    }
                }
            }
        }
    }

    
}
