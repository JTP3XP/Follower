//
//  UserMention.swift
//  TwitterClient
//
//  Created by John Patton on 9/17/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import Foundation
import SwifteriOS
import CoreData

class UserMention: NSManagedObject {
    
    static func createUserMention(mentionedUser: String, startIndex:Int, endIndex:Int, in context: NSManagedObjectContext) throws -> UserMention {

        // 
        let userMention = UserMention(context: context)
        /*
        userMention.userID = twitterJSON["id_str"].string
        userMention.startIndex = twitterJSON["screen_name"].string
        userMention.endIndex = twitterJSON["name"].string
  */
        return userMention
    }
    
    
}
