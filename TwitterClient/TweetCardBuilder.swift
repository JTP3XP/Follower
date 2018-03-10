//
//  TweetCardBuilder.swift
//  TwitterClient
//
//  Created by John Patton on 10/18/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class TweetCardBuilder {
    
    // MARK:- Class Functions
    static func buildCard(for tweet: Tweet, completionHandler: @escaping ((cardType: String, cardTitle:String, cardImageURL: String, relatedTweetURL: TweetURL)?) -> ()) {
        
        // There has to be a URL in the tweet for there to be a card
        guard let tweetUrlSet = tweet.urls, tweetUrlSet.count > 0 else {
            return
        }
        
        var tweetUrls = tweetUrlSet.allObjects as! [TweetURL]
        tweetUrls.sort { $0.startIndex < $1.startIndex }
        
        guard let cardURLString = tweetUrls.last?.urlString, let url = URL(string: cardURLString) else { // the card is always based on the last URL in the tweet
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            DispatchQueue.global(qos: .userInitiated).async {
                let htmlString = String(data: data!, encoding: String.Encoding.utf8) ?? "Couldn't get string"
                let metaData = htmlString.extractMetaData()
                
                if let cardType = metaData["twitter:card"], let cardTitle = metaData["twitter:title"] ?? metaData["og:title"] {
                    var cardImageURL: String?
                    
                    if let htmlCardImageURL = metaData["twitter:image"] ?? metaData["og:image"] {
                        cardImageURL = htmlCardImageURL
                    } else if let tweetImageSet = tweet.images, let tweetImages = tweetImageSet.allObjects as? [TweetImage], tweetImages.count > 0 {
                        // Fall back to the first attached image if the only thing missing from the card is a image and the tweet has one
                        cardImageURL = tweetImages[0].imageURL!
                    }
                    
                    if cardImageURL != nil {
                        completionHandler((cardType: cardType, cardTitle: cardTitle.htmlDecoded, cardImageURL: cardImageURL!, relatedTweetURL: tweetUrls.last!))
                    } else {
                        completionHandler(nil)
                    }
                }
            }
        }
        task.resume()
    }
}

extension String {

    var htmlDecoded: String {
        let decoded = try? NSAttributedString(data: Data(utf8), options: [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil).string
        
        return decoded ?? self
    }
    
    func matchedCaptureGroups(for regex: String) -> [[String]] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            
            var captureGroupSets = [[String]]()
            
            for result in results {
                var captureGroups = [String]()
                if result.numberOfRanges > 0 {
                    for rangeNumber in 1..<result.numberOfRanges {
                        captureGroups.append(nsString.substring(with: result.range(at: rangeNumber)))
                    }
                } else {
                    captureGroups.append(nsString.substring(with: result.range))
                }
                captureGroupSets.append(captureGroups)
            }
            
            return captureGroupSets
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return [[]]
        }
    }
    
    func extractMetaData() -> [String:String] {
        
        var extractedMetaData = [String:String]()
        
        if let open = self.range(of: "<head"), let close = self.range(of: "</head>") {
            let headTag = String(self[open.lowerBound..<close.upperBound])
            let metaPairs = headTag.matchedCaptureGroups(for: "<meta [^>]*(?:name|property)=\"([^\"]*)\" content=\"([^\"]*)\"")
            for metaPair in metaPairs {
                if metaPair.count == 2 {
                    extractedMetaData[metaPair[0]] = metaPair[1]
                }
            }
            return extractedMetaData
        }
        return [:]
    }
    
}
