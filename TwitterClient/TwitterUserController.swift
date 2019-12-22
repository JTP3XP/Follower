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
        
        swifter.getUserFollowingIDs(for: authenticatedUser, success: { json, _, _ in
            if let array = json.array {
                var twitterUserArray = [TwitterUser]()
                
                let userIDStrings = array.map({$0.string!})
                
                // We can only lookup 100 uesrs at a time, so we need to break up our requests here and stitch the results back together
                var userIDStringArrays = [[String]]()
                let numberOfUsersToLookupAtATime = 100
                var firstIndexOfThisArray = 0
                while firstIndexOfThisArray <= userIDStrings.count {
                    let lastIndexOfThisArray = min(firstIndexOfThisArray + numberOfUsersToLookupAtATime - 1, userIDStrings.count - 1)
                    let thisArray = userIDStrings[firstIndexOfThisArray...lastIndexOfThisArray]
                    userIDStringArrays.append(Array(thisArray))
                    firstIndexOfThisArray = firstIndexOfThisArray + numberOfUsersToLookupAtATime
                }
                
                for userIDStringArray in userIDStringArrays {
                    let usersArray = UsersTag.id(userIDStringArray)
                    
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
                        
                        if userIDStringArray.count < numberOfUsersToLookupAtATime { // This means we are on the last set of users to lookup
                            completionHandler(twitterUserArray)
                        }
                        
                    }, failure: { _ in
                        print("Failed to lookup users")
                    })
                }
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
