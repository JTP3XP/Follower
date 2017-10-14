//
//  TweetLinkTableViewCell.swift
//  TwitterClient
//
//  Created by John Patton on 9/24/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit

class TweetLinkTableViewCell: TweetTableViewCell {

    @IBOutlet weak var linkView: LinkView!
    
    override func updateUI() {
        super.updateUI()
        
        // Set link picture
        if let profileImageURL = tweet?.tweeter!.profileImageURL {
            let lastProfileImageURL = profileImageURL // store the URL so we can check if it is still the same before we update UI on main thread
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: URL(string: profileImageURL)!) {
                    DispatchQueue.main.async { [weak self] in
                        if profileImageURL == lastProfileImageURL { // make sure we aren't coming back to a cell that got reused for another tweet before displaying result
                            self?.linkView.linkImageView.image = UIImage(data: imageData)
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        self?.linkView.linkImageView.image = nil
                    }
                }
            }
        }
        
        // Check for twitter card information
        
        
        
    }

    // MARK: - Convenience Functions
    
    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    func extractMetaData(from html: String) -> [String:String] {
        
        var extractedMetaData = [String:String]()
        
        if let open = html.range(of: "<head>"), let close = html.range(of: "</head>") {
            let headTag = String(html[open.lowerBound..<close.upperBound])
            let metaNames = matches(for: "<meta name=\"[^\"]*\" content=\"[^\"]*\"", in: headTag)
            for metaName in metaNames {
                let stringParts = metaName.components(separatedBy: "\"")
                extractedMetaData[stringParts[1]] = stringParts[3]
            }
            return extractedMetaData
        }
        return [:]
    }
}
