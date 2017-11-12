//
//  TweetTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 7/12/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import SwifteriOS
import Foundation
import CoreData

class TweetTableViewCell: UITableViewCell {

    var tweet: Tweet? { didSet { updateUI() } }
    
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var tweetTextLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var tweetTimeLabel: UILabel!
    
   // @IBOutlet weak var outermostStackView: UIStackView!
    
    func updateUI() {
        
        guard let tweet = tweet else {
            return
        }
        
        fullNameLabel.text = tweet.tweeter!.fullName
        usernameLabel.text = "@\(tweet.tweeter!.username!)"
        tweetTextLabel.text = tweet.textWithoutEntities
        tweetTimeLabel.text = (tweet.date! as Date).generateRelativeTimestamp()
        
        // Set profile picture
        profileImageView.image = nil
        if let profileImageURL = tweet.tweeter!.profileImageURL {
            let lastProfileImageURL = profileImageURL // store the URL so we can check if it is still the same before we update UI on main thread
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: URL(string: profileImageURL)!) {
                    DispatchQueue.main.async { [weak self] in
                        if profileImageURL == lastProfileImageURL { // make sure we aren't coming back to a cell that got reused for another tweet before displaying result
                            self?.profileImageView?.image = UIImage(data: imageData)
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        if profileImageURL == lastProfileImageURL {
                            self?.profileImageView?.image = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Lifecycle methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
    }

}
