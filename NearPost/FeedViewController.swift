//
//  FeedViewController.swift
//  NearPost
//
//  Created by Hari Kolasani on 7/29/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class FeedViewController: UITableViewController {
    
    var posts:[Post] = [Post]()
   
    var unfetchedBeaconsSet:Set<String> = Set<String>()
    
    var allFetchedBeaconsSet:Set<String> = Set<String>()
    
    var timer:NSTimer?
    var timer1:NSTimer?
    
    let refreshQueue = dispatch_queue_create("com.bluecloudsys.NearPost.Refresh", nil); //creates a serial queue
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationItem.title = "NearPost"
        
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "testPost"), animated: true)
        //self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refresh"), animated: true)
        
        self.tableView.rowHeight  = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 200
        
         self.setNavStyle()
    }
    
    func setNavStyle() {
        
        var backButtonItem:UIBarButtonItem  = UIBarButtonItem(title: "", style:.Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButtonItem
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 52/255, green: 170/255, blue: 220/255, alpha: 1.0)
        
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict as [NSObject : AnyObject]
        
        let attrDict = [NSForegroundColorAttributeName: UIColor.whiteColor(),NSFontAttributeName:UIFont(name: "Avenir-Medium", size: 20)!]

        self.navigationController?.navigationBar.titleTextAttributes = attrDict
        
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.whiteColor()
        self.navigationItem.backBarButtonItem?.tintColor = UIColor.whiteColor()
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.translucent = false
        
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        appDelegate.loginToSFDC()

    }
    
    func startTimer() {
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(5   , target: self, selector: Selector("refresh"), userInfo: nil, repeats: true);
    }

    override func viewWillDisappear(animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        appDelegate.stopAdvertizing()
        
        self.stopTimer()
    }
    
    func refresh() {
        
        dispatch_async(self.refreshQueue!) {
            
            self.populate()
        }
    }
    
    func populate() {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        dispatch_async(appDelegate.rangedBeaconsAccessQueue!) {
            
            var rangedBeaconsSet:Set<String> = Set(appDelegate.getRangedBeacons())
            
            if (rangedBeaconsSet.count > 0  || self.unfetchedBeaconsSet.count > 0) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.loadPosts(rangedBeaconsSet)
                })
            }
        }
    }
    
    func loadPosts (rangedBeaconsSet:Set<String>) {
        
        var tobeFetchedBeaconsSet:Set<String> = Set<String>()
        
        if (rangedBeaconsSet.count > 0) {
            tobeFetchedBeaconsSet = rangedBeaconsSet.subtract(self.allFetchedBeaconsSet).union(self.unfetchedBeaconsSet)  //include new and unfectehd
        }
        else {
            tobeFetchedBeaconsSet = Set(self.unfetchedBeaconsSet)  //just the unfectehd Beacon Set
        }
        
        if(tobeFetchedBeaconsSet.count == 0) {
            return
        }
        
        self.unfetchedBeaconsSet = Set<String>() //initialize unfetched beacons set.
        
        var tobeFetachedBeacons:[String] = Array(tobeFetchedBeaconsSet)
        
        var newPosts:[Post] = SFDCDataManager.fetchPosts(tobeFetachedBeacons)
        var newPostsWithImages:[Post] = [Post]()
        
        
        var fetchedBeaconsSet:Set<String> = Set<String>()
        
        for var i = 0; i < newPosts.count; i++ {
            
            var newPost:Post = newPosts[i]
            
            if let thumbURL = newPost.thumbURL {
                if let imageData = SFDCDataManager.getImage(thumbURL) {
                    newPost.thumbnail = imageData
                }
            }
            
            fetchedBeaconsSet.insert(newPost.beaconId!)
            
            self.allFetchedBeaconsSet.insert(newPost.beaconId!)
            
            newPostsWithImages.append(newPost)
        }
        
        //Gather any unfetched beacons: This scenario exists as SOSL sometimes may not fetch the post right away.SOSL is indexed asynchronously
        //You can't rely on the results being available in real-time, or even within a few seconds after the final commit.
        self.unfetchedBeaconsSet = Set(tobeFetchedBeaconsSet.subtract(fetchedBeaconsSet))
        
        self.insertRowsForNewPosts(newPostsWithImages)
        
        //var newPosts:[Post] = SFDCDataManager.testFetchPosts(self.newlyRangedBeacons)
    }
    
    func testPost() {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        var postText:String = "The phenomenon known as El Niño is brewing in the Pacific Ocean - and it could be one of the strongest on "
        
        let result = self.post(postText)
        
        self.showAlert("Advertized Successfully", message: "\(result?.beaconId)")
    }
    
    func post(postText:String) -> (success:Bool,beaconId:String)? {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        return appDelegate.post(postText)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showAlert(title:String,message:String) {
        
        var alertView = UIAlertView();
        alertView.addButtonWithTitle("Ok");
        alertView.title = title;
        alertView.message = message;
        
        dispatch_async(dispatch_get_main_queue(), {
            alertView.show();
        })
    }
    
    func insertRowsForNewPosts(newPosts:[Post]) {
        
        var indexPaths = [NSIndexPath]()
        
        for var i = 0; i < newPosts.count; i++ {
            
            var newPost:Post = newPosts[i]
            
            let indexPath = NSIndexPath(forRow: i, inSection: 0)
            indexPaths.append(indexPath)
            self.posts.insert(newPost, atIndex: i)
        }
        
        tableView.beginUpdates()
        tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Top)
        tableView.endUpdates()
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView,numberOfRowsInSection section: Int) -> Int {
        return self.posts.count
    }
    
    override func tableView(tableView: UITableView,cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell:FeedViewCell? = tableView.dequeueReusableCellWithIdentifier("FeedCell") as? FeedViewCell
        
        if(cell == nil) {
            cell = FeedViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "FeedCell")
        }

        cell!.selectionStyle = UITableViewCellSelectionStyle.None
        
        var post:Post = posts[indexPath.row]
        
        cell?.populateCell(post)
        
        return cell!
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //self.selectedBeacon = self.beacons[indexPath.row]
        
        //self.performSegueWithIdentifier("ShowPosts", sender: nil)
        
    }
    
    func stopTimer() {
        self.timer?.invalidate()
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}




