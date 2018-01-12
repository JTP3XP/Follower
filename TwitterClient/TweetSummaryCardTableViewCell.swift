//
//  TweetLinkTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 9/24/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit

class TweetSummaryCardTableViewCell: TweetTableViewCell {

    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardSubtitleLabel: UILabel!
    
    override func updateUI() {
        super.updateUI()
        
        // Set card title
        cardTitleLabel.text = tweet?.card?.title ?? "Link"
        
        // Set card subtitle
        cardSubtitleLabel.text = tweet?.card?.relatedTweetURL?.urlString ?? ""
        
        // Set link picture
        cardImageView.image = nil
        if let linkImageURL = tweet?.card?.imageURL {
            cardImageView.kf.setImage(with: URL(string: linkImageURL))
        }
        
        // Set up a tap gesture recognizer on all parts of the card
        let cardViews: [UIView] = [cardImageView, cardTitleLabel, cardSubtitleLabel]
        
        for cardView in cardViews {
            let cardTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
            cardView.isUserInteractionEnabled = true
            cardView.addGestureRecognizer(cardTapGestureRecognizer)
        }
    }
    
    override func cancelUpdateUI() {
        super.cancelUpdateUI()
        cardImageView.kf.cancelDownloadTask()
    }

    @objc func cardTapped() {
        print("Card tapped")
        if let cardURLString = tweet?.card?.relatedTweetURL?.urlString, let cardURL = URL(string: cardURLString) {
            //UIApplication.shared.open(cardURL, options: [:], completionHandler: nil)
            askDelegateToOpenInSafariViewController(url: cardURL)
        }
    }
    
}
