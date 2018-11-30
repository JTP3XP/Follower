//
//  AccountImageTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 11/26/18.
//  Copyright © 2018 JohnPattonXP. All rights reserved.
//

import UIKit
import Kingfisher

class AccountImageTableViewCell: UITableViewCell {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    
    // MARK: Lifecycle methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let profileImageURL = authenticatedUser?.profileImageURL {
            profileImageView.kf.setImage(with: URL(string: profileImageURL))
        }
        
        if let fullName = authenticatedUser?.fullName {
            fullNameLabel.text = fullName
        } else {
            fullNameLabel.text = ""
        }
        
        if let username = authenticatedUser?.username {
            usernameLabel.text = "@\(username)"
        } else {
            usernameLabel.text = ""
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.masksToBounds = false
        profileImageView.layer.borderColor = UIColor.black.cgColor
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
    }

}
