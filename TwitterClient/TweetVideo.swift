//
//  TweetVideo.swift
//  TwitterClient
//
//  Created by John Patton on 2/22/19.
//  Copyright © 2019 JohnPattonXP. All rights reserved.
//

import UIKit
import CoreData
import SwifteriOS

class TweetVideo: NSManagedObject {
    
    class func findOrCreateTweetVideo(matching tweetMediaJSON: JSON, in context: NSManagedObjectContext) throws -> TweetVideo {
        
        // Need to fix this guard statement to detect video attributes, remove image indicies
        guard let tweetMediaID = tweetMediaJSON["id_str"].string, (tweetMediaJSON["type"].string == "video" || tweetMediaJSON["type"].string == "animated_gif") else {
            enum TweetError: Error {
                case runtimeError(String)
            }
            throw TweetError.runtimeError("Passed incompatible JSON to findOrCreateTweetVideo")
        }
        
        let request: NSFetchRequest<TweetVideo> = TweetVideo.fetchRequest()
        request.predicate = NSPredicate(format: "id = %@", tweetMediaID)
        
        do {
            let matches = try context.fetch(request)
            if matches.count > 0 {
                assert(matches.count == 1, "TweetVideo.findOrCreateTweetVideo -- database inconsistency!")
                return matches[0]
            }
        } catch {
            throw error
        }
        
        // It wasn't in the database already, so create it
        let tweetVideo = TweetVideo(context: context)
        tweetVideo.id = tweetMediaID
        //tweetVideo.videoImageURL = tweetMediaJSON["media_url_https"].string // This is the JSON path for an image, not a video
        
        let variantsJSON = tweetMediaJSON["video_info"]["variants"]
        tweetVideo.videoURL = urlForHighestQualityVariant(matching: variantsJSON)
        
        return tweetVideo
        
    }
    
    private class func urlForHighestQualityVariant(matching variantsJSON: JSON) -> String {
        // Bitrate might be 0 for a GIF
        var highestBitrate = -1.0
        var highestBitrateURL = ""
        if let variantJSONArray = variantsJSON.array {
            for variantJSON in variantJSONArray {
                if let thisBitrate = variantJSON["bitrate"].double, thisBitrate > highestBitrate, let thisURL = variantJSON["url"].string {
                    highestBitrate = thisBitrate
                    highestBitrateURL = thisURL
                }
            }
        }
        return highestBitrateURL
    }
    
}
