//
//  ThreadedTweetTableViewController.swift
//  TwitterClient
//
//  Created by John Patton on 7/4/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import SwifteriOS
import SafariServices
import Kingfisher
import GSImageViewerController

class ThreadedTweetTableViewController: UITableViewController, TweetTableViewCellDelegate {

    var threadedTweets = [[Tweet]]()
    var navigationBarTitle: String?
    
    @IBOutlet weak var titleNavigationItem: UINavigationItem!
    
    private enum TweetTableContents {
        case action((text: String, date: Date))
        case tweet(Tweet)
    }
    
    internal var lastTableElementIndex: (section: Int, row: Int) = (0, 0) // Storing as a variable lets us skip doing this count in the willDisplay:forRowAt method
    private var threadedTweetTableContents = [[TweetTableContents]]() {
        didSet {
            lastTableElementIndex = (threadedTweetTableContents.count - 1, threadedTweetTableContents[threadedTweetTableContents.count - 1].count - 1)
        }
    }
    
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
    
    // MARK:- Tweet Table View Cell Delegate
    func openInSafariViewController(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
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
            cell.delegate = self
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
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let tweetCell = cell as? TweetTableViewCell {
            tweetCell.cancelUpdateUI()
        }
    }
 
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.prefetchDataSource = self
        
        if let tableTitle = navigationBarTitle {
            titleNavigationItem.title = tableTitle
        }
        
        tableView.rowHeight = UITableViewAutomaticDimension // Autosize based on cell contents
        tableView.estimatedRowHeight = 120
        
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        loadTable()
        
    }
    
    // MARK:- Data Loading
    
    internal func loadTable() {
        threadedTweetTableContents = generateTableContents()
    }
    
    private func generateTableContents() -> [[TweetTableContents]] {
        
        var tableContents = [[TweetTableContents]]()
        
        for threadedTweet in threadedTweets {
            var sectionContents = [TweetTableContents]()
            for tweet in threadedTweet{
                sectionContents = sectionContentsAfterAppending(tweet: tweet, to: sectionContents)
            }
            tableContents.append(sectionContents)
        }
        return tableContents
    }
    
    // This needs to be a recursive function so we can properly arrange retweets of quoted tweets (also quotes of quoted tweets if that is possible)
    private func sectionContentsAfterAppending(tweet: Tweet, to sectionContents: [TweetTableContents]) -> [TweetTableContents] {
        var resultSectionContents = sectionContents
        if tweet.isARetweet {
            // add an action before a retweet since actions are their own row in the table
            let retweetAction = TweetTableContents.action(("\(tweet.tweeter!.fullName!) retweeted:",(tweet.date! as Date)))
            resultSectionContents.append(retweetAction)
            resultSectionContents = sectionContentsAfterAppending(tweet: tweet.isARetweetOf!, to: resultSectionContents) // add the original tweet instead of the retweet
        } else if tweet.isAQuote {
            let quoteAction = TweetTableContents.action(("\(tweet.tweeter!.fullName!) quoted:",(tweet.date! as Date)))
            resultSectionContents.append(quoteAction)
            resultSectionContents = sectionContentsAfterAppending(tweet: tweet.isAQuoteOf!, to: resultSectionContents) // Put the quoted tweet first so it reads chronologically
            resultSectionContents.append(TweetTableContents.tweet(tweet))
        } else {
            resultSectionContents.append(TweetTableContents.tweet(tweet))
        }
        return resultSectionContents
    }
    
}

extension ThreadedTweetTableViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        var urls = [URL]()
        
        for indexPath in indexPaths {
            if case .tweet(let tweet) = threadedTweetTableContents[indexPath.section][indexPath.row] {
                if let cardURLString = tweet.card?.imageURL, let cardURL = URL(string: cardURLString) {
                    urls.append(cardURL)
                }
                if let profileImageURLString = tweet.tweeter?.profileImageURL, let profileImageURL = URL(string: profileImageURLString) {
                    urls.append(profileImageURL)
                }
                if let tweetImages = tweet.images?.allObjects as? [TweetImage] {
                    for tweetImage in tweetImages {
                        if let imageURLString = tweetImage.imageURL, let imageURL = URL(string: imageURLString) {
                            urls.append(imageURL)
                        }
                    }
                }
            }
        }
        
        ImagePrefetcher(urls: urls).start()
    }
}

extension ThreadedTweetTableViewController {
    
    func present(image: UIImage, from view: UIView) {
        let imageInfo = GSImageInfo(image: image, imageMode: .aspectFit)
        let transitionInfo = GSTransitionInfo(fromView: view)
        let imageViewer = GSImageViewerController(imageInfo: imageInfo, transitionInfo: transitionInfo)
        present(imageViewer, animated: true, completion: nil)
    }

}
