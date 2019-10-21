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
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var tweetTimeLabel: UILabel!
    @IBOutlet weak var profileImageButton: UIButton!
    @IBOutlet weak var tweetTextView: UITextView!
       
    func updateUI() {
        
        guard let tweet = tweet else {
            return
        }
        
        fullNameLabel.text = tweet.tweeter!.fullName
        usernameLabel.text = "@\(tweet.tweeter!.username!)"
        tweetTextView.attributedText = NSAttributedString(string: tweet.displayText ?? "", attributes: [.font: UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body))])
        tweetTimeLabel.text = (tweet.date! as Date).generateRelativeTimestamp()
        
        // Set profile picture
        profileImageView.image = nil
        if let profileImageURL = tweet.tweeter!.profileImageURL {
            profileImageView.kf.setImage(with: URL(string: profileImageURL))
        }
        
        // Make URLs into links
        for case let url as TweetURL in tweet.urls! {
            if let displayURLString = url.displayURLString, let fullURL = url.expandedURLString {
                let linkedText = NSMutableAttributedString(attributedString: tweetTextView.attributedText)
                let hyperlinked = linkedText.setAsLink(textToFind: displayURLString, linkURL: fullURL)
                
                if hyperlinked {
                    tweetTextView.attributedText = NSAttributedString(attributedString: linkedText)
                }
            }
        }
    }
    
    func cancelUpdateUI() {
        profileImageView.kf.cancelDownloadTask()
    }
    
    @IBAction func tappedProfileImageButton(_ sender: UIButton) {
        if let delegateThatLoadsTimelines = delegate, let selectedUser = tweet?.tweeter {
            delegateThatLoadsTimelines.loadTimeline(forSelected: selectedUser)
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
        
        let fixedWidth = tweetTextView.frame.size.width
        let newSize = tweetTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        tweetTextView.frame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
    }

    func askDelegateToOpenInSafariViewController(url: URL) {
        if let delegateThatOpensSafari = delegate {
            delegateThatOpensSafari.openInSafariViewController(url: url)
        }
    }
}

protocol TweetTableViewCellDelegate {
    func openInSafariViewController(url: URL)
    func loadTimeline(forSelected user: TwitterUser)
    func playVideo(fromURL: URL)
}

extension NSMutableAttributedString {
    public func setAsLink(textToFind:String, linkURL:String) -> Bool {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            
            self.addAttribute(.link, value: linkURL, range: foundRange)
            
            return true
        }
        return false
    }
}
