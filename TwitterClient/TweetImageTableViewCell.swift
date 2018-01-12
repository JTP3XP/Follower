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
    
    override func updateUI() {
        super.updateUI()
        
        guard let tweet = tweet, let tweetImageSet = tweet.images, tweetImageSet.count > 0 else {
            return
        }
        
        let tweetImages = tweetImageSet.allObjects as! [TweetImage]
        let numberOfImages = tweetImages.count
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
        
        for imageNumber in 0..<numberOfImages {
            // Create and add an image view for each image
            let newImageView = UIImageView(frame: CGRect(x: CGFloat(imageNumber) * scrollViewWidth, y: 0, width: scrollViewWidth, height: scrollViewHeight))
            newImageView.contentMode = .scaleAspectFill
            scrollView.addSubview(newImageView)
            
            if let imageURL = tweetImages[imageNumber].imageURL {
                newImageView.kf.indicatorType = .activity
                newImageView.kf.setImage(with: URL(string: imageURL))
            }
            
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
    
}
