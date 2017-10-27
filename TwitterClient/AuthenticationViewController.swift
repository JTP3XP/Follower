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

class AuthenticationViewController: UIViewController, SFSafariViewControllerDelegate {
    
    var swifter: Swifter!
    var authorizedToken: Credential.OAuthAccessToken?
    
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
        if let _ = UserDefaults.standard.array(forKey: "token") {
            login()
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
            return "oauth_token=\(tokenPartsArray[0])&oauth_token_secret=\(tokenPartsArray[1])&user_id=\(tokenPartsArray[2])&screen_name=\(tokenPartsArray[3])&x_auth_expires=0"
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
        performSegue(withIdentifier: "LoginSuccess", sender: self)
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
