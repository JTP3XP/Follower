//
//  OrientationEnforcer.swift
//  TwitterClient
//
//  Created by John Patton on 11/19/18.
//  Copyright © 2018 JohnPattonXP. All rights reserved.
//

import Foundation
import UIKit

struct OrientationEnforcer {
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
    
    /// Method to adjust lock and rotate to the desired orientation
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
        
        self.lockOrientation(orientation)
        
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }
    
}
