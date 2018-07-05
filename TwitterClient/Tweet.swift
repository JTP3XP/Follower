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
    
    var displayText: String? {
        get {
            if let tweetText = text, let upperBound = tweetText.index(tweetText.startIndex, offsetBy: Int(displayTextEndIndex), limitedBy: tweetText.endIndex) {
                let lowerBound = tweetText.index(tweetText.startIndex, offsetBy: Int(displayTextStartIndex))
                let displayedPortionOfText = String(tweetText[lowerBound..<upperBound])
                return displayedPortionOfText
            }
            return text
        }
    }
    
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
        
        // Get display text range since we use extended tweets
        if let startIndex = tweetJSON["display_text_range"][0].integer, let endIndex = tweetJSON["display_text_range"][1].integer {
            tweet.displayTextStartIndex = Int16(startIndex)
            tweet.displayTextEndIndex = Int16(endIndex)
        }
        
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
        if let isQuoteStatus = tweetJSON["is_quote_status"].bool, isQuoteStatus == true && quotedStatus != .invalid && quotedStatus != .null {
            tweet.isAQuote = true
            do {
                try tweet.isAQuoteOf = findOrCreateTweet(matching: quotedStatus, in: context)
            } catch {
                tweet.isAQuote = false
            }
        } else {
            tweet.isAQuote = false
        }
        
        // Get user
        do {
            tweet.tweeter = try TwitterUser.findOrCreateTwitterUser(matching: tweetJSON["user"], in: context)
        } catch {
            print("Error finding or creating tweeter for tweet: \(error)")
        }
        
        if let tweeter = tweet.tweeter {
            // This will not be nil for the followed users beacuse of the way we record this when loading the followed users, and we do not care to log this for anyone else because this is just used to indicate unread tweets from followed users
            if let timestampToUpdate = tweeter.mostRecentTweetTimestamp, let dateToCompare = tweet.date, timestampToUpdate < dateToCompare {
                tweeter.mostRecentTweetTimestamp = tweet.date
            }
            
            // We only add tweets to the database when they are being loaded for display, so we always count them as read here. May need to reconsider if tweets start getting loaded for other reasons.
            if tweeter.mostRecentReadTweetTimestamp == nil {
                tweeter.mostRecentReadTweetTimestamp = tweet.date
            } else if let timestampToUpdate = tweeter.mostRecentReadTweetTimestamp, let dateToCompare = tweet.date, timestampToUpdate < dateToCompare {
                tweeter.mostRecentReadTweetTimestamp = tweet.date
            }
        }
        
        // Get entities
        if let urlJSONArray = tweetJSON["entities"]["urls"].array {
            for urlJSON in urlJSONArray {
                if let urlString = urlJSON["url"].string, let startIndex = urlJSON["indices"][0].integer, let endIndex = urlJSON["indices"][1].integer {
                    let newUrl = TweetURL.createTweetURL(from: urlString, startIndex: startIndex, endIndex: endIndex, in: context)
                    newUrl.tweet = tweet
                }
            }
        }
        
        // Get images
        if let mediaJSONArray = tweetJSON["extended_entities"]["media"].array {
            for mediaJSON in mediaJSONArray where mediaJSON["type"] == "photo" {
                do {
                    let newImage = try TweetImage.createTweetImage(matching: mediaJSON, in: context)
                    newImage.tweet = tweet
                } catch {
                    throw error
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
