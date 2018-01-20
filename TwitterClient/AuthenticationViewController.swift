//
//  AuthenticationViewController.swift
//  TwitterClient
//
//  Created by John Patton on 6/17/17.
//  Copyright © 2017 JohnPattonXP.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit
import Accounts
import Social
import SwifteriOS
import SafariServices
import CoreData

class AuthenticationViewController: UIViewController, SFSafariViewControllerDelegate {
    
    var swifter: Swifter!
    var authorizedToken: Credential.OAuthAccessToken?
    @IBOutlet weak var loginButton: UIButton!
    
    private struct API {
        static let key : String = "cpB8erNVGtNs3d089Mq7yGEa2"
        static let secret : String = "R2fc5uuuwnQ20JdiGYNYLnjMvT93Q7PpLll3muKCdiYEOnQPyI"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        swifter = appDelegate.swifter
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawAndAnimateLoginScreen() { [weak self] in
            if let _ = UserDefaults.standard.array(forKey: "token") {
                self?.login()
            } else {
                if let loginButton = self?.loginButton {
                    self?.view.bringSubview(toFront: loginButton)
                }
            }
        }
    }
    
    @IBAction func didTouchUpInsideLoginButton(_ sender: UIButton) {
        login()
    }
    
    func login() {
        let failureHandler: (Error) -> Void = { error in
            self.alert("Error", message: error.localizedDescription)
        }
        
        func assembleTokenQueryString(from tokenPartsArray: [String]) -> String {
            return "oauth_token=\(tokenPartsArray[0])&oauth_token_secret=\(tokenPartsArray[1])&user_id=\(tokenPartsArray[3])&screen_name=\(tokenPartsArray[2])&x_auth_expires=0"
        }
        
        let url = URL(string: "swifter://success")!
        
        // Try to get a previously used token
        if let savedTokenPartsArray = UserDefaults.standard.array(forKey: "token") as? [String] {
            authorizedToken = Credential.OAuthAccessToken.init(queryString: assembleTokenQueryString(from: savedTokenPartsArray))
        }
        
        if authorizedToken == nil {
            // only authorize if we have not already
            swifter.authorize(with: url, presentFrom: self, success: { [weak self] token, response in
                
                // Save token
                let tokenPartsArray: [String] = [
                    token!.key,
                    token!.secret,
                    token!.screenName!,
                    token!.userID!
                ]
                
                UserDefaults.standard.setValue(tokenPartsArray, forKeyPath: "token")
                
                // Use token
                self?.authorizedToken = token
                self?.continueAfterSuccessfulLogin()
                }, failure: failureHandler)
        } else {
            continueAfterSuccessfulLogin()
        }
    }
    
    func continueAfterSuccessfulLogin() {
        let twitterUserController = TwitterUserController()
        twitterUserController.updateFollowedUsers {
            self.performSegue(withIdentifier: "LoginSuccess2", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LoginSuccess2" {
            if let twitterUserCollectionViewController = segue.destination.contents as? TwitterUserCollectionViewController {
                let twitterUserController = TwitterUserController()
                // TODO: Enhance sorting to be more helpful
                let sortClosure: (TwitterUser, TwitterUser) -> Bool = { return $0.fullName!.uppercased() < $1.fullName!.uppercased() }
                twitterUserCollectionViewController.displayedUsers = twitterUserController.getMyFollowedUsers(sortedBy: sortClosure)
            }
        }
    }
    
    func alert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}

// MARK:- Extensions

extension UIViewController {
    
    var contents: UIViewController {
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController ?? self
        } else {
            return self
        }
    }
}

extension UIViewController {
    
    func drawAndAnimateLoginScreen(completionHandler: @escaping (() -> Void)) {
        let containerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 375.0, height: 667.0))
        containerView.addBackground()
        self.view.addSubview(containerView)
        
        let twitterBlue = UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1)
        
        let bigCircleRadius: CGFloat = 145/2
        let smallCircleRadius: CGFloat = bigCircleRadius/2
        let pointsToLeftOfBigCircle: CGFloat = 14
        let pointsAboveBigCircle: CGFloat = 35 + (containerView.frame.height >= 812 ? 30 : 0)
        let verticalLineCenter: CGFloat = pointsToLeftOfBigCircle + bigCircleRadius
        let verticalLineWidth: CGFloat = 8
        let distanceBetweenCircles: CGFloat = 34
        
        // Big circle
        let circle = UIButton(frame:  CGRect(x: 0.0, y: 0.0, width: 300.0, height: 300.0))
        circle.center = containerView.center
        circle.layer.cornerRadius = circle.frame.width / 2
        circle.titleLabel?.text = "Follower"
        let attributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.font: UIFont(name: "AmericanTypewriter-Semibold", size: 52)!,
            NSAttributedStringKey.foregroundColor: UIColor.white
        ]
        let title = NSAttributedString(string: "Follower", attributes: attributes)
        circle.setAttributedTitle(title, for: .normal)
        circle.backgroundColor = twitterBlue
        
        // Set target location for big circle
        let target = UIView(frame: CGRect(x: 0.0, y: 0.0, width: bigCircleRadius * 2, height: bigCircleRadius * 2))
        target.center = CGPoint(x: verticalLineCenter, y: pointsAboveBigCircle + bigCircleRadius)
        target.layer.cornerRadius = target.frame.width / 2
        target.backgroundColor = .clear
        //target.layer.borderWidth = 2.0
        
        // Vertical line
        let line = UIView(frame: CGRect(x: verticalLineCenter - verticalLineWidth/2, y: 0, width: verticalLineWidth, height: containerView.frame.height))
        line.backgroundColor = twitterBlue
        line.transform = CGAffineTransform.init(translationX: 0, y: -containerView.frame.height)
        
        // Smaller Circles
        let firstSmallCircleCenterY: CGFloat = target.center.y + bigCircleRadius + smallCircleRadius + distanceBetweenCircles
        var smallCircles = [UIView]()
        var topOfNextCircle: CGFloat = firstSmallCircleCenterY - smallCircleRadius
        var circleIndex = 0
        while topOfNextCircle < containerView.frame.height {
            let newCircleCenterY: CGFloat = firstSmallCircleCenterY + CGFloat(circleIndex) * (smallCircleRadius + distanceBetweenCircles + smallCircleRadius)
            let newCircle = UIView(frame: CGRect(x: 0, y: 0, width: smallCircleRadius * 2, height: smallCircleRadius * 2))
            newCircle.center = CGPoint(x: verticalLineCenter, y: newCircleCenterY)
            newCircle.layer.cornerRadius = newCircle.frame.width / 2
            newCircle.backgroundColor = twitterBlue
            newCircle.transform = CGAffineTransform.init(scaleX: 0, y: 0)
            
            smallCircles.append(newCircle)
            
            // Calculate condition for while loop
            topOfNextCircle = newCircleCenterY + smallCircleRadius + distanceBetweenCircles
            circleIndex = circleIndex + 1
        }
        
        containerView.addSubview(target)
        containerView.addSubview(line)
        containerView.addSubview(circle)
        _ = smallCircles.map({ containerView.addSubview($0) })
        
        let secondsBeforeAnimation = 1
        let bigCircleAnimationSeconds: TimeInterval = 1.0
        let dropLineAnimationSeconds: TimeInterval = 1.0
        let smallCircleAnimationSeconds: TimeInterval = 0.5
        
        let moveAndScaleAnimation = {
            // Scale and move
            let scaleValue: CGFloat = target.frame.width / circle.frame.width
            let scale = CGAffineTransform(scaleX: scaleValue, y: scaleValue)
            circle.transform = scale
            circle.center = target.center
        }
        
        let dropLineAnimation = {
            // Scale and move
            line.transform = CGAffineTransform.identity
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(secondsBeforeAnimation)) {
            UIView.animate(withDuration: bigCircleAnimationSeconds, animations: moveAndScaleAnimation) { finished in
                
                _ = smallCircles.map({ smallCircle in
                    let delaySeconds = Double(smallCircle.center.y / containerView.frame.height) * Double(dropLineAnimationSeconds)
                    UIView.animate(withDuration: smallCircleAnimationSeconds, delay: delaySeconds, usingSpringWithDamping: 0.65, initialSpringVelocity: 2.0, options:[], animations: { smallCircle.transform = CGAffineTransform.identity }, completion: nil)
                })
                
                UIView.animate(withDuration: dropLineAnimationSeconds, animations: dropLineAnimation) { finished in
                    completionHandler()
                }
                
            }
        }
    }
    
}

extension UIView {
    func addBackground(imageName: String = "Gradient Gray Background", contextMode: UIViewContentMode = .scaleToFill) {
        // setup the UIImageView
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
        backgroundImageView.image = UIImage(named: imageName)
        backgroundImageView.contentMode = contentMode
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backgroundImageView)
        sendSubview(toBack: backgroundImageView)
        
        // adding NSLayoutConstraints
        let leadingConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailingConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let topConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        let bottomConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }
}
