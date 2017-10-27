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
                case runtimeError(String)
            }
            throw TweetError.runtimeError("Passed a non-Tweet to findOrCreateTweet")
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
        
        // It wasn't in the database already, so create it - start with easy stuff
        let tweet = Tweet(context: context)
        tweet.id = tweetID
        tweet.parentID = tweetJSON["in_reply_to_status_id_str"].string
        tweet.text = tweetJSON["full_text"].string?.replacingEscapedTweetCharacters() ?? tweetJSON["text"].string?.replacingEscapedTweetCharacters() ?? ""
        tweet.originalJSON = "\(tweetJSON)"
        
        // Get date
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        tweet.date = formatter.date(from: tweetJSON["created_at"].string!)!
        
        // Check if it is a retweet
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
        
        // Check if it is a quote
        let quotedStatus = tweetJSON["quoted_status"]
        if quotedStatus != .invalid && quotedStatus != .null {
            tweet.isAQuote = true
            do {
                try tweet.isAQuoteOf = findOrCreateTweet(matching: retweetedStatus, in: context)
            } catch {
                tweet.isAQuote = false
            }
        } else {
            tweet.isAQuote = false
        }
        
        // Get user
        tweet.tweeter = try? TwitterUser.findOrCreateTwitterUser(matching: tweetJSON["user"], in: context)
        
        // Get entities
        if let urlJSONArray = tweetJSON["entities"]["urls"].array {
            for urlJSON in urlJSONArray {
                if let urlString = urlJSON["url"].string, let startIndex = urlJSON["indices"][0].integer, let endIndex = urlJSON["indices"][1].integer {
                    let newUrl = TweetURL.createTweetURL(from: urlString, startIndex: startIndex, endIndex: endIndex, in: context)
                    newUrl.tweet = tweet
                }
            }
        }

        // Build card if tweet should have one
        if let tweetURLCount = tweet.urls?.count, tweetURLCount > 0 {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            TweetCardBuilder.buildCard(for: tweet) { resultTuple in
                if let cardTuple = resultTuple {
                    let tweetCard = TweetCard(context: context)
                    tweetCard.imageURL = cardTuple.cardImageURL
                    tweetCard.title = cardTuple.cardTitle
                    tweetCard.type = cardTuple.cardType
                    tweetCard.relatedTweetURL = cardTuple.relatedTweetURL
                    tweetCard.tweet = tweet
                }
                dispatchGroup.leave()
            }
        }
        
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
