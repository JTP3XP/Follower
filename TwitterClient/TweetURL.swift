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

    static func createTweetURL(from urlString: String, startIndex:Int, endIndex:Int, in context: NSManagedObjectContext) -> TweetURL {

        let tweetURL = TweetURL(context: context)
        tweetURL.urlString = urlString
        tweetURL.startIndex = Int16(startIndex)
        tweetURL.endIndex = Int16(endIndex)
        
        return tweetURL
    }
    
}
