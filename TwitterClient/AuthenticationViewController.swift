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

class AuthenticationViewController: UIViewController {
    
    var swifter: Swifter!
    var authorizedToken: Credential.OAuthAccessToken?
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OrientationEnforcer.lockOrientation(.portrait, andRotateTo: .portrait)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        OrientationEnforcer.lockOrientation(.allButUpsideDown)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        swifter = appDelegate.swifter
    
        OrientationEnforcer.lockOrientation(.portrait, andRotateTo: .portrait)
        loginButton.isHidden = false
        
        // Check if we already have a token and login without waiting for user input if we do
        if let savedTokenPartsArray = UserDefaults.standard.array(forKey: "token") as? [String] {
            authorizedToken = Credential.OAuthAccessToken.init(queryString: assembleTokenQueryString(from: savedTokenPartsArray))
            if authorizedToken != nil {
                login()
            }
        }
    }
    
    @IBAction func didTouchUpInsideLoginButton(_ sender: UIButton) {
        login()
    }
    
    func assembleTokenQueryString(from tokenPartsArray: [String]) -> String {
        return "oauth_token=\(tokenPartsArray[0])&oauth_token_secret=\(tokenPartsArray[1])&user_id=\(tokenPartsArray[3])&screen_name=\(tokenPartsArray[2])&x_auth_expires=0"
    }
    
    func login() {
        let failureHandler: (Error) -> Void = { error in
            self.alert("Whoops!", message: "We ran into an issue when logging you in. Please try again.")
            self.loginButton.isEnabled = true
        }
        
        // Set UI to how it should look while we are logging in
        loginButton.setImage(UIImage(named: "Twitter Logging In Button"), for: .disabled)
        loginButton.isEnabled = false
        
        let url = URL(string: "swifter://success")!
        
        // Try to get a previously used token
        if let savedTokenPartsArray = UserDefaults.standard.array(forKey: "token") as? [String] {
            authorizedToken = Credential.OAuthAccessToken.init(queryString: assembleTokenQueryString(from: savedTokenPartsArray))
        } else {
            authorizedToken = nil // This clears out the token when the user has logged out, but this view controller had the token from a previous login
        }
         
        if authorizedToken == nil {
            // only authorize if we have not already
            swifter.authorize(withCallback: url, presentingFrom: self, safariDelegate: self, success: { [weak self] token, response in

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
            self.performSegue(withIdentifier: "LoginSuccess", sender: self)
            
            // Reset the UI in case the user logs out later and this is back on screen
            self.loginButton.isEnabled = true
        }

        // Get the current user's info so we have it on hand for later
        if let currentUserID = authorizedToken?.userID {
            let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
            let mainContext = container!.viewContext
            
            _ = swifter.showUser(UserTag.id(currentUserID), success: { userJSON in
                do {
                    try authenticatedUser = TwitterUser.findOrCreateTwitterUser(matching: userJSON, in: mainContext)
                    try mainContext.save()
                }
                catch {
                    print("Ran into an issue getting authenticated user info: \(error)")
                }
            }, failure: { _ in print("showUser failed for user ID \(currentUserID)") })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LoginSuccess" {
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

extension AuthenticationViewController: SFSafariViewControllerDelegate {
    @available(iOS 9.0, *)
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        loginButton.isEnabled = true
        controller.dismiss(animated: true, completion: nil)
    }
}
