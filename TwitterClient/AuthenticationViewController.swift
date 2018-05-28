//
//  AuthenticationViewController.swift
//  TwitterClient
//
//  Created by John Patton on 6/17/17.
//  Copyright © 2017 JohnPattonXP.
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
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    private struct API {
        static let key : String = "cpB8erNVGtNs3d089Mq7yGEa2"
        static let secret : String = "R2fc5uuuwnQ20JdiGYNYLnjMvT93Q7PpLll3muKCdiYEOnQPyI"
    }
    
    private struct loginScreen {
        var backgroundImage: UIImage {
            var backgroundImageName = ""
            switch UIScreen.main.bounds.height {
            case 568:
                backgroundImageName = "4 inch Login Screen"
            case 667:
                backgroundImageName = "4.7 inch Login Screen"
            case 736:
                backgroundImageName = "5.5 inch Login Screen"
            case 812:
                backgroundImageName = "5.8 inch Login Screen"
            default:
                break
            }
            return UIImage(named: backgroundImageName)!
        }
        
        var loginButtonRect: CGRect {
            var buttonRect = CGRect()
            switch UIScreen.main.bounds.height {
            case 568:
                buttonRect = CGRect(x: 19, y: 499, width: 283, height: 40)
            case 667:
                buttonRect = CGRect(x: 23, y: 592, width: 329, height: 47)
            case 736:
                buttonRect = CGRect(x: 28, y: 648, width: 359, height: 51)
            case 812:
                buttonRect = CGRect(x: 23, y: 678, width: 329, height: 47)
            default:
                break
            }
            return buttonRect
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        swifter = appDelegate.swifter
        let thisLoginScreen = loginScreen()
        
        backgroundImageView.image = thisLoginScreen.backgroundImage
        loginButton.frame = thisLoginScreen.loginButtonRect
        loginButton.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
