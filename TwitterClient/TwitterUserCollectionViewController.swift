//
//  TwitterUserCollectionViewController.swift
//  TwitterClient
//
//  Created by John Patton on 11/17/17.
//  Copyright © 2017 JohnPattonXP. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher

private let reuseIdentifier = "Twitter User Cell"

class TwitterUserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    var displayedUsers = [TwitterUser]()
    
    let margin: CGFloat = 5
    let cellsPerRow = 2
    
    internal var loadingView: UIAlertController?
    
    // MARK:- Refreshing
    
    @objc private func checkTwitterForUpdates() {
 
        let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        guard let context = container?.viewContext else { return }
        
        for user in displayedUsers {
            user.refresh(in: context) { [weak self] _ in
                if self != nil {
                    for cell in self?.collectionView!.visibleCells as! [TwitterUserCollectionViewCell] {
                        cell.updateUI()
                    }
                }
            }
        }
    }
    
    // MARK:- View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.prefetchDataSource = self
        
        // Listen for the app becoming active - this could happen after hours of being inactive, so there could definitely be new unread tweets
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(checkTwitterForUpdates), name: UIApplication.didBecomeActiveNotification , object: nil)
        
        guard let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowLayout.minimumInteritemSpacing = margin
        flowLayout.minimumLineSpacing = margin
        flowLayout.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        OrientationEnforcer.lockOrientation(.portrait)
        
        // The user may have read tweets and then returned back to this view, so update the UI to pick up any changes in unread status
        for cell in collectionView!.visibleCells as! [TwitterUserCollectionViewCell] {
            cell.updateUI()
        }
        
        // It's also possible that followed users have been tweeting while this view was in the background, so check for any updates
        checkTwitterForUpdates()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        OrientationEnforcer.lockOrientation(.allButUpsideDown)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedUsers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TwitterUserCollectionViewCell
    
        // Clear out any existing content
        cell.profileImageView.image = nil
        cell.unreadGlowImageView.image = nil
        
        // Configure the cell
        cell.twitterUser = displayedUsers[indexPath.row]
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedUser = displayedUsers[indexPath.row]
        loadTimeline(for: selectedUser)

    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let marginsAndInsets = flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    // MARK: - Temporary
    
    @IBAction func testButtonPressed(_ sender: UIBarButtonItem) {
        let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        guard let context = container?.viewContext else { return }
        deleteTweetsIfUserWantsTo(using: context)
    }
    
    func deleteTweetsIfUserWantsTo(using context: NSManagedObjectContext) {
        let deleteAlert = UIAlertController(title: "Clear existing Tweets?", message: "This is only for testing.", preferredStyle: UIAlertController.Style.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tweet")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(batchDeleteRequest)
                try context.save()
            } catch {
                print("Error deleting data")
            }
        }))
        
        deleteAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
            return
        }))
        
        present(deleteAlert, animated: true, completion: nil)
    }

}

extension TwitterUserCollectionViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { URL(string: displayedUsers[$0.row].profileImageURL ?? "") }
        ImagePrefetcher(urls: urls).start()
    }
}

extension TwitterUserCollectionViewController: UserTimelineLoader {}

extension TwitterUserCollectionViewController: CAAnimationDelegate {}
