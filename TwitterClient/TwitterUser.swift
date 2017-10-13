//
//  TwitterUser.swift
//  TwitterClient
//
//  Created by John Patton on 9/2/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import Foundation
import SwifteriOS
import CoreData

class TwitterUser: NSManagedObject {
    
    static func findOrCreateTwitterUser(matching twitterJSON: JSON, in context: NSManagedObjectContext) throws -> TwitterUser {
        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate = NSPredicate(format: "userID = %@", twitterJSON["id_str"].string!)
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TwitterUser.findOrCreateTwitterUser -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let twitterUser = TwitterUser(context: context)
        twitterUser.userID = twitterJSON["id_str"].string
        twitterUser.username = twitterJSON["screen_name"].string
        twitterUser.fullName = twitterJSON["name"].string
        twitterUser.profileImageURL = twitterJSON["profile_image_url_https"].string?.replacingOccurrences(of: "_normal.", with: ".")
        
        /*
        // In case we want to fetch more user info ...
        DispatchQueue.global(qos: .userInitiated).async {
            if let swifter = (UIApplication.shared.delegate as! AppDelegate).swifter {
                _ = swifter.showUser(for: UserTag.id(twitterUser.userID!), success: { userJSON in
                    print("\(userJSON)")
                }, failure: { _ in print("showUser failed for user ID \(twitterUser.userID!)") })
            }
            
        }
        */
        
        return twitterUser
    }
    
    
}
