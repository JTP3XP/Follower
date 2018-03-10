//
//  TweetLinkTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 9/24/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit

class TweetSummaryCardTableViewCell: TweetTableViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var cardImageView: UIImageView!
    @IBOutlet weak var cardTitleLabel: UILabel!
    @IBOutlet weak var cardSubtitleLabel: UILabel!
    
    private var cardType: CardType?
    
    private enum CardType {
        case image
        case video
    }
    
    override func updateUI() {
        super.updateUI()
        let cardViews: [UIView] = [cardImageView, cardTitleLabel, cardSubtitleLabel]
        cardType = cardImageView.bounds.width == cardImageView.bounds.height ? .video : .image

        // Setup card formatting
        cardView.clipsToBounds = true
        
        // Set card title
        cardTitleLabel.text = tweet?.card?.title ?? "Link"
        
        // Set card subtitle
        cardSubtitleLabel.text = tweet?.card?.relatedTweetURL?.urlString ?? ""
        
        // Set link picture
        cardImageView.image = nil
        if let linkImageURL = tweet?.card?.imageURL {
            cardImageView.kf.setImage(with: URL(string: linkImageURL))
        }
        
        // Add border between image and title
        var edgeThatNeedsBorder: UIRectEdge
        if let borderColor = cardView.borderColor, let cardType = cardType {
            switch cardType {
            case .image:
                edgeThatNeedsBorder = UIRectEdge.bottom
            case .video:
                edgeThatNeedsBorder = UIRectEdge.right
            }
            cardImageView.layer.addBorder(edge: edgeThatNeedsBorder, color: borderColor, thickness: cardView.borderWidth)
        }
        
        // Set up a tap gesture recognizer on all parts of the card
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

extension CALayer {
    
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        
        let border = CALayer()
        
        switch edge {
        case UIRectEdge.top:
            border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: thickness)
            break
        case UIRectEdge.bottom:
            border.frame = CGRect.init(x: 0, y: frame.height - thickness, width: frame.width, height: thickness)
            break
        case UIRectEdge.left:
            border.frame = CGRect.init(x: 0, y: 0, width: thickness, height: frame.height)
            break
        case UIRectEdge.right:
            border.frame = CGRect.init(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
            break
        default:
            break
        }
        
        border.backgroundColor = color.cgColor;
        
        self.addSublayer(border)
    }
}
