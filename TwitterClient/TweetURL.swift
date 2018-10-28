//
//  TweetURL.swift
//  TwitterClient
//
//  Created by John Patton on 10/14/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import CoreData
import SwifteriOS

class TweetURL: NSManagedObject {
    
    static func createTweetURL(from urlJSON: JSON, partOf tweet: Tweet, in context: NSManagedObjectContext) -> TweetURL {
        
        let tweetURL = TweetURL(context: context)
        
        tweetURL.tweet = tweet
        
        if let urlString = urlJSON["url"].string, let displayURLString = urlJSON["display_url"].string, let expandedURLString = urlJSON["expanded_url"].string {
            tweetURL.twitterVersionOfURLString = urlString
            tweetURL.displayURLString = displayURLString
            tweetURL.expandedURLString = expandedURLString
        }
        
        if let startIndex = urlJSON["indices"][0].integer, let endIndex = urlJSON["indices"][1].integer {
            tweetURL.startIndex = Int16(startIndex)
            tweetURL.endIndex = Int16(endIndex)
        }
        
        return tweetURL
    }
    
}
