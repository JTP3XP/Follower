//
//  TwitterUserTableViewController.swift
//  TwitterClient
//
//  Created by John Patton on 9/2/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreData

class TwitterUserTableViewController: UITableViewController {

    var swifter: Swifter!
    let userNameList = ["@elonmusk"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        swifter = appDelegate.swifter
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return userNameList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Twitter User Cell", for: indexPath)

        cell.textLabel?.text = "Elon Musk"
        cell.detailTextLabel?.text = userNameList[indexPath.row]

        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let selectedUserName = userNameList[indexPath.row]
        let selectedUserID = "44196397"
        
        fetchTwitterHomeStream(forUserID: selectedUserID)
    }
    
    // MARK: - Temporary code
    
    @IBAction func testButtonPressed(_ sender: UIBarButtonItem) {
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Test tweet", message: "Use this to print tweet JSON to console", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.text = ""
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Print JSON", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            if let tweetID = textField?.text {
                self.swifter.getTweet(forID: tweetID, tweetMode: .extended, success: { testTweet in
                    print(testTweet)
                })
                
            }
        }))
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
        
    }


    // MARK: - Stuff that may move later
    func fetchTwitterHomeStream(forUserID userID: String) {
        
        let failureHandler: (Error) -> Void = { error in
            self.alert(title: "Error", message: error.localizedDescription)
        }
        
        self.swifter.getTimeline(for: userID, count: 20, tweetMode: TweetMode.extended, success: { [weak self] json in
            // Successfully fetched timeline, so lets create and push the table view
            
            let threadedTweetTableViewController = self?.storyboard!.instantiateViewController(withIdentifier: "ThreadedTweetTableViewController") as! ThreadedTweetTableViewController
            guard let tweetsJSON = json.array else { return }
            
            let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
            guard let context = container?.viewContext else { return }
            
            var threadedTweets = [[Tweet]]()
            for tweetJSON in tweetsJSON {
                let tweet = try? Tweet.findOrCreateTweet(matching: tweetJSON, in: context)
                do {
                    try context.save()
                } catch {
                    fatalError("Failure to save context: \(error)")
                }
                
                let tweetThreader = TweetThreader()
                tweetThreader.swifter = self?.swifter
                tweetThreader.tweet = tweet
                //print("\(tweet.id) - Creating thread...")
                tweetThreader.createThread { threadedTweet in
                    DispatchQueue.main.async {
                        threadedTweets.append(threadedTweet!)
                        //print("Now we have \(threadedTweets.count) threads of tweets")
                        
                        if threadedTweets.count == tweetsJSON.count {
                            let uniqueThreadedTweets = TweetThreader.removeRedundantThreads(from: threadedTweets)
                            let sortedThreadedTweets = TweetThreader.sortChronologically(threadedTweets: uniqueThreadedTweets)
                            threadedTweetTableViewController.threadedTweets = sortedThreadedTweets
                            self?.navigationController?.pushViewController(threadedTweetTableViewController, animated: true)
                        }
                    }
                }
                //print("\(tweet.id) - Finished loop")
            }
            
            //print("Done with all loops")
            
            }, failure: failureHandler)
        
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}