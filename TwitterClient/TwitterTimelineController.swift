//
//  TwitterTimelineController.swift
//  TwitterClient
//
//  Created by John Patton on 11/23/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import Foundation
import SwifteriOS
import UIKit
import CoreData

class TwitterTimelineController {
    
    var swifter: Swifter
    var context: NSManagedObjectContext
    var tweetsPerFetch = 20
    var maxTweetID: String?
    
    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        swifter = appDelegate.swifter
        
        let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        context = container!.viewContext
    }
    
    func fetchThreadedTimeline(forUserID userID: String, completionHandler: @escaping ([[Tweet]]) -> ()) {
        
        self.swifter.getTimeline(for: userID, count: tweetsPerFetch, maxID: maxTweetID, tweetMode: TweetMode.extended, success: { json in
            
            guard let tweetsJSON = json.array else { return }
            
            var threadedTweets = [[Tweet]]()
            for tweetJSON in tweetsJSON {
                
                //guard let context = self.context else { return }
                
                let tweet = try? Tweet.findOrCreateTweet(matching: tweetJSON, in: self.context)
                do {
                    try self.context.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
                
                print("MaxID: \(self.maxTweetID ?? "none") ID: \((tweet?.id)!) Date:\((tweet?.date)!)")
                
                let tweetThreader = TweetThreader()
                tweetThreader.swifter = self.swifter
                tweetThreader.tweet = tweet
                tweetThreader.createThread { threadedTweet in
                    DispatchQueue.main.async {
                        threadedTweets.append(threadedTweet!)
                        if threadedTweets.count == tweetsJSON.count {
                            let uniqueThreadedTweets = TweetThreader.removeRedundantThreads(from: threadedTweets)
                            let sortedThreadedTweets = TweetThreader.sortChronologically(uniqueThreadedTweets)
                            completionHandler(sortedThreadedTweets)
                        }
                    }
                }
            }
            }, failure: nil)
        
    }
}
