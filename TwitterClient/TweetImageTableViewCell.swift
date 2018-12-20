//
//  TweetImageTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 11/10/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import Kingfisher

class TweetImageTableViewCell: TweetTableViewCell, UIScrollViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var numberOfImages = 0
    var scrollViewImageViews = [UIImageView]()
    
    override func updateUI() {
        super.updateUI()
        
        guard let tweet = tweet, let tweetImageSet = tweet.images, tweetImageSet.count > 0 else {
            return
        }
        
        let tweetImages = tweetImageSet.allObjects as! [TweetImage]
        numberOfImages = tweetImages.count
        pageControl.numberOfPages = numberOfImages
        pageControl.currentPage = 0
        
        let scrollViewWidth: CGFloat = scrollView.frame.width
        let scrollViewHeight: CGFloat = scrollView.frame.height
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(numberOfImages), height: scrollView.frame.height)

        for subview in scrollView.subviews {
            // Clear out images from the last use of the cell
            subview.removeFromSuperview()
        }
        
        scrollViewImageViews = [UIImageView]() // Clear this out for new cell
        
        for imageNumber in 0..<numberOfImages {
            // Create and add an image view for each image
            let newImageView = UIImageView(frame: CGRect(x: CGFloat(imageNumber) * scrollViewWidth, y: 0, width: scrollViewWidth, height: scrollViewHeight))
            newImageView.contentMode = .scaleAspectFill
            scrollView.addSubview(newImageView)
            
            if let imageURL = tweetImages[imageNumber].imageURL {
                newImageView.kf.indicatorType = .activity
                newImageView.kf.setImage(with: URL(string: imageURL))
            }
            
            // Add a tap gesture recognizer so we can present the image if tapped
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(sender:)))
            newImageView.addGestureRecognizer(tapRecognizer)
            newImageView.isUserInteractionEnabled = true
            
            // Add to array of image views so we can easily resize when we layout subviews
            scrollViewImageViews.append(newImageView)
        }
    }

    override func cancelUpdateUI() {
        super.cancelUpdateUI()
        for subview in scrollView.subviews {
            // Clear out images from the last use of the cell
            if let imageView = subview as? UIImageView {
                imageView.kf.cancelDownloadTask()
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView){
        // Test the offset and calculate the current page after scrolling ends
        let pageWidth: CGFloat = scrollView.frame.width
        let currentPage: CGFloat = floor((scrollView.contentOffset.x-pageWidth/2)/pageWidth)+1
        // Change the indicator
        self.pageControl.currentPage = Int(currentPage)
    }
    
    @objc func imageTapped(sender: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            if let senderImageView = sender.view as? UIImageView, let senderImage = senderImageView.image {
                delegate.imageInCellWasTapped(image: senderImage, tappedView: senderImageView)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let scrollViewWidth: CGFloat = scrollView.frame.width
        let scrollViewHeight: CGFloat = scrollView.frame.height
        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: scrollView.frame.width * CGFloat(numberOfImages), height: scrollView.frame.height)
        
        var imageIndex = 0
        
        for imageView in scrollViewImageViews {
            imageView.frame = CGRect(x: CGFloat(imageIndex) * scrollViewWidth, y: 0, width: scrollViewWidth, height: scrollViewHeight)
            imageIndex = imageIndex + 1
        }
    }
}

extension TweetTableViewCellDelegate {
    func imageInCellWasTapped(image: UIImage, tappedView: UIImageView) {
        if let presentingViewController = self as? ThreadedTweetTableViewController {
            presentingViewController.present(image: image, from: tappedView)
        } else {
            print("Tried to present image using something other than a ThreadedTweetTableViewController")
        }
    }
}
