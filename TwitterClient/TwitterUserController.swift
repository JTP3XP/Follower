//
//  TwitterUserController.swift
//  TwitterClient
//
//  Created by John Patton on 11/21/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import Foundation
import SwifteriOS
import UIKit
import CoreData

class TwitterUserController {
    
    var swifter: Swifter
    var context: NSManagedObjectContext
    var authenticatedUser: UserTag
    
    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        swifter = appDelegate.swifter
        
        let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        context = container!.viewContext
        
        // Get authenticated user info from the saved token used to authenticate
        let tokenPartsArray = UserDefaults.standard.array(forKey: "token") as! [String]
        authenticatedUser = .id(tokenPartsArray[3])
    }
    
    func getMyFollowedUsersFromTwitter(completionHandler: @escaping ([TwitterUser]) -> ()) {
        
        swifter.getUserFollowingIDs(for: authenticatedUser, stringifyIDs: true, success: { json, _, _ in
            if let array = json.array {
                let userIDStrings = array.map({$0.string!})
                let usersArray = UsersTag.id(userIDStrings)
                var twitterUserArray = [TwitterUser]()
                self.swifter.lookupUsers(for: usersArray, success: { (json) in
                    guard let twitterUserJSONArray = json.array else { return }

                    for twitterUserJSON in twitterUserJSONArray {
                        do {
                            let followedUser = try TwitterUser.findOrCreateTwitterUser(matching: twitterUserJSON, in: self.context)
                            twitterUserArray.append(followedUser)
                            if followedUser.isFollowed == false {
                                followedUser.isFollowed = true
                            }
                        } catch {
                            print("Error getting followed user")
                        }
                    }

                    do {
                        try self.context.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }

                    completionHandler(twitterUserArray)
                    
                }, failure: { _ in })
            }
        })
    }
    
    func getMyFollowedUsers(sortedBy sortClosure: ((TwitterUser, TwitterUser) -> Bool)? = nil) -> [TwitterUser] {
        var databaseFollowedUsers = [TwitterUser]()
        let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
        request.predicate = NSPredicate(format: "isFollowed = true")
        do {
            databaseFollowedUsers = try context.fetch(request)
        } catch {
            print("Error getting followed users from database")
        }
        
        if let sortClosure = sortClosure {
            databaseFollowedUsers.sort(by: sortClosure)
        }
        
        return databaseFollowedUsers
    }
    
    func updateFollowedUsers(completionHandler: @escaping () -> ()) {
        
        let databaseFollowedUsers = getMyFollowedUsers()
        
        getMyFollowedUsersFromTwitter { currentFollowedUsers in
            
            let usersThatHaveBeenUnfollowed = databaseFollowedUsers.filter { !currentFollowedUsers.contains($0) }
            var databaseChangeWasMade = false
            
            for unfollowedUser in usersThatHaveBeenUnfollowed {
                unfollowedUser.isFollowed = false
                databaseChangeWasMade = true
            }
            
            if databaseChangeWasMade {
                do {
                    try self.context.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
            }
            
            completionHandler()
            
        }
    }
    
}
