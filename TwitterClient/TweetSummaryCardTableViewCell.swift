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
    @IBOutlet weak var CardImageLoadingIndicator: UIActivityIndicatorView!
    
    override func updateUI() {
        super.updateUI()
        
        // Set card title
        cardTitleLabel.text = tweet?.card?.title ?? "Link"
        
        // Set card subtitle
        cardSubtitleLabel.text = tweet?.card?.relatedTweetURL?.urlString ?? ""
        
        // Set link picture
        cardImageView.image = nil
        CardImageLoadingIndicator.startAnimating()
        if let linkImageURL = tweet?.card?.imageURL {
            let lastLinkImageURL = linkImageURL // store the URL so we can check if it is still the same before we update UI on main thread
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: URL(string: linkImageURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!) {
                    DispatchQueue.main.async { [weak self] in
                        if linkImageURL == lastLinkImageURL { // make sure we aren't coming back to a cell that got reused for another tweet before displaying result
                            self?.cardImageView.image = UIImage(data: imageData)
                            self?.CardImageLoadingIndicator.stopAnimating()
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.cardImageView.image = nil
                    }
                }
            }
        }
        
        // Set up a tap gesture recognizer on all parts of the card
        let cardViews: [UIView] = [cardImageView, cardTitleLabel, cardSubtitleLabel]
        
        for cardView in cardViews {
            let cardTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
            cardView.isUserInteractionEnabled = true
            cardView.addGestureRecognizer(cardTapGestureRecognizer)
        }
    }

    @objc func cardTapped() {
        print("Card tapped")
        if let cardURLString = tweet?.card?.relatedTweetURL?.urlString, let cardURL = URL(string: cardURLString) {
            //UIApplication.shared.open(cardURL, options: [:], completionHandler: nil)
            askDelegateToOpenInSafariViewController(url: cardURL)
        }
    }
    
}
