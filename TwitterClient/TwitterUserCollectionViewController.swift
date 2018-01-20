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
    
    let margin: CGFloat = 10
    let cellsPerRow = 2
    
    @IBAction func testButtonPressed(_ sender: UIBarButtonItem) {
        let container: NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        guard let context = container?.viewContext else { return }
        deleteTweetsIfUserWantsTo(using: context)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.prefetchDataSource = self
        
        guard let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowLayout.minimumInteritemSpacing = margin
        flowLayout.minimumLineSpacing = margin
        flowLayout.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
 
    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedUsers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TwitterUserCollectionViewCell
    
        // Configure the cell
        cell.twitterUser = displayedUsers[indexPath.row]
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let twitterTimelineController = TwitterTimelineController()
        guard let selectedUserID = displayedUsers[indexPath.row].userID else { return }
        twitterTimelineController.fetchThreadedTimeline(forUserID: selectedUserID) { [weak self] (threadedTimelineTweets) in
            let threadedTweetTableViewController = self?.storyboard!.instantiateViewController(withIdentifier: "ThreadedTweetTableViewController") as! ThreadedTweetTableViewController
            threadedTweetTableViewController.threadedTweets = threadedTimelineTweets
            threadedTweetTableViewController.navigationBarTitle = self?.displayedUsers[indexPath.row].fullName
            self?.navigationController?.pushViewController(threadedTweetTableViewController, animated: true)
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let marginsAndInsets = flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing * CGFloat(cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(cellsPerRow)).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    // MARK: - Temporary
    
    func deleteTweetsIfUserWantsTo(using context: NSManagedObjectContext) {
        let deleteAlert = UIAlertController(title: "Clear existing Tweets?", message: "This is only for testing.", preferredStyle: UIAlertControllerStyle.alert)
        
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tweet")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try context.execute(batchDeleteRequest)
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
        let urls = indexPaths.flatMap { URL(string: displayedUsers[$0.row].profileImageURL ?? "") }
        ImagePrefetcher(urls: urls).start()
    }
}
