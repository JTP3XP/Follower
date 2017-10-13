//
//  Date+Extension.swift
//  TwitterClient
//
//  Created by John Patton on 9/22/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import Foundation

extension Date {

    func generateRelativeTimestamp() -> String {
        
        let elapsedSeconds = Date().timeIntervalSince(self)
        
        switch elapsedSeconds {
        case 0..<60:
            
            return "Just now"
            
        case 60..<60*60: // Within 1 hour - xx mins ago
            
            let dateComponentsFormatter = DateComponentsFormatter()
            dateComponentsFormatter.allowedUnits = [.minute]
            let unitLabel = (elapsedSeconds >= 60 && elapsedSeconds < 120) ? "minute" : "minutes"
            return "\(dateComponentsFormatter.string(from: elapsedSeconds)!) \(unitLabel) ago"
            
        case _ where Calendar.current.isDateInToday(self): // Current day - xx hours ago
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return "Today \(dateFormatter.string(from: self))"
            
        case _ where Calendar.current.isDateInYesterday(self): // Yesterday - "Yesterday" Time
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return "Yesterday \(dateFormatter.string(from: self))".replacingOccurrences(of: " AM", with: "\u{A0}AM").replacingOccurrences(of: " PM", with: "\u{A0}PM")
            
        default: // Else - Date Time
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            var result = dateFormatter.string(from: self).replacingOccurrences(of: ",", with: "") // get rid of the comma separating the date and time
            result = result.replacingOccurrences(of: " AM", with: "\u{A0}AM").replacingOccurrences(of: " PM", with: "\u{A0}PM") // do not let the line break right before the AM or PM text
            return result
            
        }
    }

}
