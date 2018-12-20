//
//  TwitterUserCollectionViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 11/17/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import Kingfisher

class TwitterUserCollectionViewCell: UICollectionViewCell {
    
    var twitterUser: TwitterUser? {
        didSet {
            if twitterUser != oldValue || profileImageView.image == nil { // We might dequeue a cell for the same user as previously shown in the cell, so we need to check for a nil image as well
                updateUI()
            }
        }
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var unreadGlowImageView: UIImageView!
    
    func updateUI() {
        
        guard let twitterUser = twitterUser else {
            return
        }
        
        fullNameLabel.text = twitterUser.fullName
        usernameLabel.text = "@\(twitterUser.username!)"
        
        // Set profile picture
        if let profileImageURL = twitterUser.profileImageURL {
            let image = UIImage(named: "Twitter Default User Image")
            if profileImageView.image == nil {
                // We clear the image when we dequeue the cell, so this will always be null when we need to update it
                profileImageView.kf.setImage(with: URL(string: profileImageURL), placeholder: image)
            }
        }
        
        // Set unread glow
        if let mostRecentTweetTimestamp = twitterUser.mostRecentTweetTimestamp, let mostRecentReadTweetTimestamp = twitterUser.mostRecentReadTweetTimestamp, mostRecentTweetTimestamp > mostRecentReadTweetTimestamp {
            unreadGlowImageView.image = #imageLiteral(resourceName: "Unread Tweet Glow")
        } else {
            unreadGlowImageView.image = nil
        }
    }
    
    // MARK: Lifecycle methods
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        profileImageView.layer.cornerRadius = self.profileImageView.bounds.width / 2
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.clipsToBounds = true
    }
}
