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
import Kingfisher

class TweetTableViewCell: UITableViewCell {

    var tweet: Tweet? { didSet { updateUI() } }
    var delegate: TweetTableViewCellDelegate?
    
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
        tweetTextLabel.text = tweet.displayText
        tweetTimeLabel.text = (tweet.date! as Date).generateRelativeTimestamp()
        
        // Set profile picture
        profileImageView.image = nil
        if let profileImageURL = tweet.tweeter!.profileImageURL {
            profileImageView.kf.setImage(with: URL(string: profileImageURL))
        }
    }
    
    func cancelUpdateUI() {
        profileImageView.kf.cancelDownloadTask()
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

    func askDelegateToOpenInSafariViewController(url: URL) {
        if let delegateThatOpensSafari = delegate {
            delegateThatOpensSafari.openInSafariViewController(url: url)
        }
    }
}

protocol TweetTableViewCellDelegate {
    func openInSafariViewController(url: URL)
}
