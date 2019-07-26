//
//  TweetImage.swift
//  TwitterClient
//
//  Created by John Patton on 11/11/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import CoreData
import SwifteriOS

class TweetImage: NSManagedObject {

    class func createTweetImage(matching tweetMediaJSON: JSON, in context: NSManagedObjectContext) throws -> TweetImage {
        
        guard let tweetMediaID = tweetMediaJSON["id_str"].string, tweetMediaJSON["type"].string == "photo", let startIndex = tweetMediaJSON["indices"][0].integer, let endIndex = tweetMediaJSON["indices"][1].integer else {
            enum TweetError: Error {
                case runtimeError(String)
            }
            throw TweetError.runtimeError("Passed incompatible JSON to createTweetImage")
        }
        
        let request: NSFetchRequest<TweetImage> = TweetImage.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", tweetMediaID)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TweetImage.createTweetImage -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        // It wasn't in the database already, so create it
        let tweetImage = TweetImage(context: context)
        tweetImage.id = tweetMediaID
        tweetImage.imageURL = tweetMediaJSON["media_url_https"].string
        tweetImage.startIndex = Int16(startIndex)
        tweetImage.endIndex = Int16(endIndex)
        
        return tweetImage
        
    }
    
}
