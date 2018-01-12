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
    
    var twitterUser: TwitterUser? { didSet { updateUI() } }
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    func updateUI() {
        
        guard let twitterUser = twitterUser else {
            return
        }
        
        fullNameLabel.text = twitterUser.fullName
        usernameLabel.text = "@\(twitterUser.username!)"
        
        // Set profile picture
        profileImageView.image = nil
        if let profileImageURL = twitterUser.profileImageURL {
            profileImageView.kf.setImage(with: URL(string: profileImageURL))
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
