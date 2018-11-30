//
//  AuthenticatedUserController.swift
//  TwitterClient
//
//  Created by John Patton on 11/26/18.
//  Copyright © 2018 JohnPattonXP. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class AuthenticatedUserController {
    
    // MARK: - Properties
    
    static let shared = AuthenticatedUserController(user: authenticatedUser!)
    
    // MARK: -
    
    let user: TwitterUser
    
    // Initialization
    
    private init(user: TwitterUser) {
        self.user = user
        // Get the user's profile image into the cache so we can display it quickly later
        ImagePrefetcher(urls: [URL(string: user.profileImageURL!)!]).start()
    }
    
}
