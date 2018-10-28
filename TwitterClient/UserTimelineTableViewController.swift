//
//  UserTimelineTableViewController.swift
//  TwitterClient
//
//  Created by John Patton on 7/30/18.
//  Copyright © 2018 JohnPattonXP. All rights reserved.
//

import UIKit

class UserTimelineTableViewController: ThreadedTweetTableViewController {

    var user: TwitterUser?
    var currentlyLoadingMoreTweets = false
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        if (indexPath.section, indexPath.row) == lastTableElementIndex {
            if let tweetUserID = user?.userID {
                
                if currentlyLoadingMoreTweets { return }
                
                // Find the last tweetID for the user whose timeline we are viewing - ignoring tweets brought in by the threading process because they could be from far in the past
                let flatTweets = threadedTweets.map { $0.last! }
                
                
                let tweetID = flatTweets.reduce(Int.max) { (result, tweet) -> Int in
                    if tweet.tweeter == user, let tweetIDInt = Int(tweet.id!) {
                        if result > tweetIDInt { print("Found older tweet \(tweetIDInt) from \(tweet.date!)") }
                        return min(result, tweetIDInt)
                    } else {
                        return min(result, Int.max)
                    }
                }
                
                // We need to fetch more from Twitter
                let twitterTimelineController = TwitterTimelineController()
                
                guard tweetID != Int.max else { return }
                currentlyLoadingMoreTweets = true
                twitterTimelineController.maxTweetID = "\(tweetID - 1)" // Substracting 1 avoids refetching the last tweet shown
                twitterTimelineController.fetchThreadedTimeline(forUserID: tweetUserID) { [weak self] (threadedTimelineTweets) in
                    
                    if let existingThreadedTweets = self?.threadedTweets {
                        let existingWithNewThreadedTweets = existingThreadedTweets + threadedTimelineTweets
                        let updatedThreadedTweets = TweetThreader.removeRedundantThreads(from: existingWithNewThreadedTweets)
                        
                        self?.threadedTweets = updatedThreadedTweets
                        // Now reload the table view
                        self?.loadTable()
                        self?.tableView.reloadData()
                        self?.currentlyLoadingMoreTweets = false
                        
                    }
                }
            }
        }
    }
    
    override func loadTimeline(forSelected user: TwitterUser) {
        if let displayedUser = self.user, displayedUser != user {
            loadTimeline(for: user)
        }
    }

}
