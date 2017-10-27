//
//  TweetThreader.swift
//  TwitterClient
//
//  Created by John Patton on 6/20/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import Foundation
import SwifteriOS
import UIKit
import CoreData

class TweetThreader {
    
    var swifter: Swifter?
    var tweet: Tweet?
    let parentFetchingDispatchGroup = DispatchGroup()
    var printPrefix: String?
    let printDebugMessages = false
    
    func createThread(_ completionHandler: @escaping ([Tweet]?) -> ()) {
        
        guard let tweet = self.tweet else {
            print("Tried to create thread without setting TweetThreader's tweet variable")
            return
        }
        
        printPrefix = "\(tweet.id!) - "
        
        var threadOfTweets: [Tweet] = [tweet]
        
        // Get parent tweets
        getParentTweets(for: threadOfTweets.last!) { parentTweet in
            DispatchQueue.main.async {
                // work on main queue for all updates to the array to avoid conflicts
                if let foundParentTweet = parentTweet {
                    threadOfTweets.append(foundParentTweet)
                    if self.printDebugMessages { print("\(self.printPrefix ?? "nil - ")There are now \(threadOfTweets.count) tweets in the thread") }
                }
                if self.printDebugMessages { print("\(self.printPrefix ?? "nil - ")Leaving dispatch group") }
                self.parentFetchingDispatchGroup.leave()
            }
        }
        
        parentFetchingDispatchGroup.notify(queue: .main, execute: {
            if self.printDebugMessages { print("\(self.printPrefix ?? "nil - ")Parent fetching dispatch group came back with \(threadOfTweets.count) tweets") }
            
            threadOfTweets = threadOfTweets.reversed()
            
            for tweet in threadOfTweets {
                if self.printDebugMessages { print("\(tweet.text!)") }
            }
            completionHandler(threadOfTweets)
        })
        
        
    }
    
    func getParentTweets(for tweet: Tweet, completionHandler: @escaping (Tweet?) -> ()) {
        
        let getParentPrintPrefix = "\(tweet.id!) - "
        
        guard let swifter = swifter else {
            print("\(getParentPrintPrefix)Tried to get tweets without setting TweetThreader's swifter variable to a instance of swifter")
            return
        }
        
        if self.printDebugMessages { print("\(printPrefix ?? "nil - ")\(getParentPrintPrefix)Entering dispatch group") }
        parentFetchingDispatchGroup.enter()
        
        if let parentTweetID = tweet.parentID {
            
            swifter.getTweet(forID: parentTweetID, tweetMode: TweetMode.extended, success: { parentTweetJSON in

                let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
                guard let context = container?.viewContext else { return }
                let parentTweet = try! Tweet.findOrCreateTweet(matching: parentTweetJSON, in: context)
                do {
                    try context.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
                
                if self.printDebugMessages { print("\(self.printPrefix ?? "nil - ")\(getParentPrintPrefix)Got the parent tweet...") }
                if let grandparentTweetID = parentTweet.parentID {
                    // Now recurse
                    if self.printDebugMessages { print("\(self.printPrefix ?? "nil - ")\(getParentPrintPrefix)Getting a parent tweet's parent - \(grandparentTweetID)") }
                    self.getParentTweets(for: parentTweet, completionHandler: completionHandler)
                    
                    completionHandler(parentTweet)
                } else {
                    if self.printDebugMessages { print("\(self.printPrefix ?? "nil - ")\(getParentPrintPrefix)This is the parentest parent") }
                    completionHandler(parentTweet) // No parent for this parent, so don't recurse in this case
                }
                }, failure: { _ in
                    if self.printDebugMessages { print("\(self.printPrefix ?? "nil - ")\(getParentPrintPrefix)Looks like there is a parent tweet but we failed to get it. Parent Tweet ID = \(parentTweetID). Child Tweet ID = \(tweet.id!)") }
                    completionHandler(nil)
            })
        } else {
            // Could not get the parent or there is not a parent
            if self.printDebugMessages { print("\(printPrefix ?? "nil - ")\(getParentPrintPrefix)Did not find a parent") }
            completionHandler(nil)
        }
        
    }
    
    // MARK:- Class Functions
    
    static func removeRedundantThreads(from threadedTweets: [[Tweet]]) -> [[Tweet]] {
        // a redundant thread's tweets are fully represented in another thread that contains more tweets
        
        var uniqueThreads = [[Tweet]]()
        
        for threadedTweet in threadedTweets { // for each thread...
            var redundantTweets = 0
            for tweet in threadedTweet { // ... check if each tweet ...
                for potentialSuperSetOfThreadedTweet in threadedTweets.filter({ $0.count > threadedTweet.count}) { // ... already exists in a thread that could possibly make it redundant because it has more tweets than the thread we are testing
                    for testTweet in potentialSuperSetOfThreadedTweet {
                        if testTweet.id == tweet.id {
                            redundantTweets += 1
                        }
                    }
                }
            }
            if redundantTweets < threadedTweet.count {
                uniqueThreads.append(threadedTweet)
                //print("Found a unique thread - \(redundantTweets)/\(threadedTweet.count) redundant. Starts with \(threadedTweet[0]["text"])")
            } else {
                print("Dropped a redundant thread")
            }
        }
        
        return uniqueThreads
        
    }
    
    static func sortChronologically(_ threadedTweets: [[Tweet]]) -> [[Tweet]] {
        
        // the most recent tweet in a thread determines its sort order so that the most recent activity is always first
        
        var sortArray = [(tweetDate: Date, tweetThread: [Tweet])]()
        
        for thread in threadedTweets {
            if let lastTweet = thread.last {
                let createdDate = lastTweet.date
                sortArray.append((tweetDate: createdDate! as Date, tweetThread: thread))
            }
        }
 
        let sortedArray = sortArray.sorted { $0.tweetDate > $1.tweetDate }
        let sortedThreads = sortedArray.map { $0.tweetThread }
        
        return sortedThreads
    }
    
}
