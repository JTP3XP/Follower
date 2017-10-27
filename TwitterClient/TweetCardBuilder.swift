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
                if let cardType = metaData["twitter:card"], let cardTitle = metaData["twitter:title"], let cardImageURL = metaData["twitter:image"] {
                    completionHandler((cardType: cardType, cardTitle: cardTitle, cardImageURL: cardImageURL, relatedTweetURL: tweetUrls.last!))
                } else {
                    completionHandler(nil)
                }
            }
        }
        task.resume()
    }
}

extension String {
    
    func matches(for regex: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range) }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func extractMetaData() -> [String:String] {
        
        var extractedMetaData = [String:String]()
        
        if let open = self.range(of: "<head>"), let close = self.range(of: "</head>") {
            let headTag = String(self[open.lowerBound..<close.upperBound])
            let metaNames = headTag.matches(for: "<meta name=\"[^\"]*\" content=\"[^\"]*\"")
            for metaName in metaNames {
                let stringParts = metaName.components(separatedBy: "\"")
                extractedMetaData[stringParts[1]] = stringParts[3]
            }
            return extractedMetaData
        }
        return [:]
    }
    
}
