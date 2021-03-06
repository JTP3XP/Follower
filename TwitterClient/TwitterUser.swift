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
                let userObjectInDatabase = matches[0]
                userObjectInDatabase.update(using: twitterJSON, in: context)
                return userObjectInDatabase
            }
        } catch {
            throw error
        }
        
        let twitterUser = TwitterUser(context: context)
        twitterUser.userID = twitterJSON["id_str"].string
        twitterUser.username = twitterJSON["screen_name"].string
        twitterUser.fullName = twitterJSON["name"].string
        twitterUser.profileImageURL = twitterJSON["profile_image_url_https"].string?.replacingOccurrences(of: "_normal.", with: ".")
        
        let mostRecentTweetJSON = twitterJSON["status"]
        if mostRecentTweetJSON != .invalid {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
            if let createdAtString = mostRecentTweetJSON["created_at"].string {
                let mostRecentTweetTimestamp = formatter.date(from: createdAtString)!
                twitterUser.mostRecentTweetTimestamp = mostRecentTweetTimestamp
            }
        }
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving new user: \(error)")
            }
        }
        
        return twitterUser
    }
    
    func refresh(in context: NSManagedObjectContext, completionHandler: @escaping (TwitterUser) -> ()) {
        if let swifter = (UIApplication.shared.delegate as! AppDelegate).swifter {
            _ = swifter.showUser(UserTag.id(self.userID!), success: { userJSON in
                self.update(using: userJSON, in: context)
                completionHandler(self)
            }, failure: { _ in
                print("showUser failed for user ID \(self.userID!)")
            })
        }
    }
    
    private func update(using twitterJSON: JSON, in context: NSManagedObjectContext) {
        // This will run every time we search the database using user JSON and can be used to update anything that is expected to change over time
        
        let currentProfileImageURL = twitterJSON["profile_image_url_https"].string?.replacingOccurrences(of: "_normal.", with: ".")
        if self.profileImageURL != currentProfileImageURL {
            self.profileImageURL = currentProfileImageURL
        }
        
        let mostRecentTweetJSON = twitterJSON["status"]
        if mostRecentTweetJSON != .invalid {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
            if let createdAtString = mostRecentTweetJSON["created_at"].string {
                let mostRecentTweetTimestamp = formatter.date(from: createdAtString)!
                self.mostRecentTweetTimestamp = mostRecentTweetTimestamp
            }
        }
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving updates to user: \(error)")
            }
        }
    }
    
}
