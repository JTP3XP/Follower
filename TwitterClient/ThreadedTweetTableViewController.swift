//
//  ThreadedTweetTableViewController.swift
//  TwitterClient
//
//  Created by John Patton on 7/4/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import SwifteriOS

class ThreadedTweetTableViewController: UITableViewController {

    var threadedTweets = [[Tweet]]()
    
    private enum TweetTableContents {
        case action((text: String, date: Date))
        case tweet(Tweet)
    }
    
    private var threadedTweetTableContents = [[TweetTableContents]]()
    
    private let reuseIdentifierForBasic: String = "Basic Tweet Cell"
    private let reuseIdentifierForImage: String = "Image Tweet Cell"
    private let reuseIdentifierForSummaryCard: String = "Summary Card Tweet Cell"
    private let reuseIdentifierForPlayerCard: String = "Player Card Tweet Cell"
    private let reuseIdentifierForAction: String = "Action Cell"
    
    @objc private func refresh() {
        refreshControl?.attributedTitle = NSAttributedString(string: "Loading newer tweets")
        refreshControl?.endRefreshing()
        refreshControl?.attributedTitle = NSAttributedString(string: "Load newer tweets")
    }
    
    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return threadedTweetTableContents.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threadedTweetTableContents[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch threadedTweetTableContents[indexPath.section][indexPath.row] {
        case .tweet(let tweet):
            
            // Set default resuse identifier, then use subsequent logic to pick any non-defaults
            var reuseIdentifierForCell = reuseIdentifierForBasic
            
            if let tweetImageSet = tweet.images, tweetImageSet.count > 0 {
                reuseIdentifierForCell = reuseIdentifierForImage
            }
            
            // People often attach an image that is redundant with the card that would be built. In these cases we want to display as a card view
            if let card = tweet.card, let cardType = card.type {
                switch cardType {
                case "player":
                    reuseIdentifierForCell = reuseIdentifierForPlayerCard
                default:
                    reuseIdentifierForCell = reuseIdentifierForSummaryCard
                }
            }

            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifierForCell, for: indexPath) as! TweetTableViewCell
            cell.tweet = tweet
            return cell
        case .action(let action):
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifierForAction, for: indexPath) as! ActionTableViewCell
            cell.descriptionLabel.text = action.text
            cell.timestampLabel.text = action.date.generateRelativeTimestamp()
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Header Cell")
        return cell?.contentView
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch threadedTweetTableContents[indexPath.section][indexPath.row] {
        case .tweet(let tweet):
            let tweetJSON = tweet.originalJSON
            print(tweetJSON ?? "Could not find JSON in database")
            print("")
            print("End of tweet")
        case .action(let action):
            print("\(action.text)")
        }
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension // Autosize based on cell contents
        tableView.estimatedRowHeight = 120
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        threadedTweetTableContents = generateTableContents()
    }
    
    // MARK: - Convenience Functions
    
    private func generateTableContents() -> [[TweetTableContents]] {
        
        var tableContents = [[TweetTableContents]]()
        
        for threadedTweet in threadedTweets {
            var sectionContents = [TweetTableContents]()
            for tweet in threadedTweet{
                if tweet.isARetweet {
                    // add an action before a retweet since actions are their own row in the table
                    let retweetAction = TweetTableContents.action(("\(tweet.tweeter!.fullName!) retweeted:",(tweet.date! as Date)))
                    sectionContents.append(retweetAction)
                    sectionContents.append(TweetTableContents.tweet(tweet.isARetweetOf!)) // add the original tweet instead of the retweet
                } else {
                    sectionContents.append(TweetTableContents.tweet(tweet))
                }
            }
            tableContents.append(sectionContents)
        }
        return tableContents
    }
    
}
