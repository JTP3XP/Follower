//
//  UserTimelineLoader.swift
//  TwitterClient
//
//  Created by John Patton on 10/11/18.
//  Copyright © 2018 JohnPattonXP. All rights reserved.
//

import Foundation
import UIKit

protocol UserTimelineLoader: class {
    var loadingView: UIAlertController? { get set }
    func displayLoadingMessage(for twitterUser: TwitterUser)
}

extension UserTimelineLoader {
    
    func displayLoadingMessage(for twitterUser: TwitterUser) {
        loadingView = UIAlertController(title: nil, message: "Getting timeline...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        loadingView!.view.addSubview(loadingIndicator)
        if let thisUIViewController = self as? UIViewController {
            thisUIViewController.present(loadingView!, animated: false, completion: nil)
        }
    }
    
    func loadTimeline(for user: TwitterUser) {
        
        guard let selectedUserID = user.userID else { return }
        
        let twitterTimelineController = TwitterTimelineController()
        
        displayLoadingMessage(for: user)
        
        twitterTimelineController.fetchThreadedTimeline(forUserID: selectedUserID) { [weak self] (threadedTimelineTweets) in
            
            guard let selfUIViewController = self as? UIViewController else { return }
            
            let userTimelineTableViewController = selfUIViewController.storyboard!.instantiateViewController(withIdentifier: "UserTimelineTableViewController") as! UserTimelineTableViewController
            userTimelineTableViewController.threadedTweets = threadedTimelineTweets
            userTimelineTableViewController.user = user
            userTimelineTableViewController.navigationBarTitle = user.fullName
            
            selfUIViewController.navigationController?.pushViewController(userTimelineTableViewController, animated: true)
            
            if let displayedLoadingView = (selfUIViewController as? UserTimelineLoader)?.loadingView {
                displayedLoadingView.dismiss(animated: false, completion: nil)
            }
        }
    }
    
}
