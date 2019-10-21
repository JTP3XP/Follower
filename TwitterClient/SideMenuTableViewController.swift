//
//  SideMenuTableViewController.swift
//  TwitterClient
//
//  Created by John Patton on 11/26/18.
//  Copyright © 2018 JohnPattonXP. All rights reserved.
//

import UIKit

class SideMenuTableViewController: UITableViewController, UserTimelineLoader {
    
    var loadingView: UIAlertController?
    
    @IBOutlet weak var logOutCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            loadTimeline(for: authenticatedUser!)
        default:
            if tableView.cellForRow(at: indexPath) == logOutCell {
                UserDefaults.standard.removeObject(forKey: "token")
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            }
        }
        
    }
}
