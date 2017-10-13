//
//  Tweet.swift
//  TwitterClient
//
//  Created by John Patton on 7/22/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import Foundation
import SwifteriOS
import CoreData
import UIKit

class Tweet: NSManagedObject {
    
    class func findOrCreateTweet(matching tweetJSON: JSON, in context: NSManagedObjectContext) throws -> Tweet {
        
        guard let tweetID = tweetJSON["id_str"].string else {
            enum TweetError: Error {
                case RuntimeError(String)
            }
            throw TweetError.RuntimeError("Passed a non-Tweet to findOrCreateTweet")
        }
        
        let request: NSFetchRequest<Tweet> = Tweet.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", tweetID)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "Tweet.findOrCreateTweet -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        let tweet = Tweet(context: context)
        tweet.id = tweetID
        tweet.parentID = tweetJSON["in_reply_to_status_id_str"].string
        tweet.text = tweetJSON["full_text"].string?.replacingEscapedTweetCharacters() ?? tweetJSON["text"].string?.replacingEscapedTweetCharacters() ?? ""
        tweet.originalJSON = "\(tweetJSON)"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        tweet.date = formatter.date(from: tweetJSON["created_at"].string!)! as NSDate
        
        let retweetedStatus = tweetJSON["retweeted_status"]
        if retweetedStatus != .invalid && retweetedStatus != .null {
            tweet.isARetweet = true
            do {
                try tweet.isARetweetOf = findOrCreateTweet(matching: retweetedStatus, in: context)
            } catch {
                tweet.isARetweet = false
            }
        } else {
            tweet.isARetweet = false
        }
        
        tweet.tweeter = try? TwitterUser.findOrCreateTwitterUser(matching: tweetJSON["user"], in: context)
        
        return tweet
    }
    
}

extension String {
    
    func replacingEscapedTweetCharacters() -> String {
        
        let replacements: [(searchString: String, replacementString: String)] = [
            ("&amp;", "&"),
            ("&lt;","<"),
            ("&gt;",">")
        ]
        
        var newString = self
        
        for replacement in replacements {
            newString = newString.replacingOccurrences(of: replacement.searchString, with: replacement.replacementString)
        }
        
        return newString
    }
    
}
