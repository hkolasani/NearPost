//
//  NewPostViewController.swift
//  NearPost
//
//  Created by Hari Kolasani on 8/14/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class NewPostViewController: UIViewController,UITextViewDelegate {
    
    
    @IBOutlet var userImageView: UIImageView?
    @IBOutlet var postTextView: UITextView?
    @IBOutlet var placeHolderLabel: UILabel?
    var bulkpostcnt:Int = 0
    
    var postButton:UIBarButtonItem?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if !self.hasConnectivity() {
            self.showAlert("Warning!", message: "NearPost requires Internet Connection to function!")
        }

        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        self.navigationItem.title = "New"
        
        self.postButton = UIBarButtonItem(title: "Post", style: .Done, target: self, action: "post")
        self.navigationItem.setRightBarButtonItem(postButton, animated: true)
        self.navigationItem.setLeftBarButtonItem(UIBarButtonItem(title: "BULK", style: .Done, target: self, action: "bulk"), animated: true)
        postButton?.enabled = false
        
        self.setNavStyle()
        
        self.postTextView?.delegate = self
        
        if let imageData = SFDCDataManager.getImage(appDelegate.userThumbURL) {
            if let image = UIImage(data: imageData) {
                UIGraphicsBeginImageContext(CGSize(width: 44, height: 44))
                image.drawInRect(CGRectMake(0, 0, 44, 44))
                if let theImage = UIGraphicsGetImageFromCurrentImageContext() {
                    userImageView?.image = theImage
                }
                UIGraphicsEndImageContext();
            }
        }
    }
    
    func setNavStyle() {
        
        var backButtonItem:UIBarButtonItem  = UIBarButtonItem(title: "", style:.Plain, target: nil, action: nil)
        self.navigationItem.backBarButtonItem = backButtonItem
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 52/255, green: 170/255, blue: 220/255, alpha: 1.0)
        
        let titleDict: NSDictionary = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.titleTextAttributes = titleDict as [NSObject : AnyObject]
        
        let attrDict = [NSForegroundColorAttributeName: UIColor.whiteColor(),NSFontAttributeName:UIFont(name: "Avenir-Medium", size: 20)!]
        
        self.navigationController?.navigationBar.titleTextAttributes = attrDict
        
        self.postButton?.setTitleTextAttributes(attrDict,forState: UIControlState.Normal)
        
        self.postTextView?.font = UIFont(name: "Avenir-Book", size: 16)
        self.postTextView?.becomeFirstResponder()
        
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
        
        appDelegate.relogin {
            self.postButton?.enabled = true
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        if let txt = textView.text {
            if count(txt) > 0 {
                postButton?.enabled = true
                self.placeHolderLabel?.hidden = true;
            }
            else {
                postButton?.enabled = false
                self.placeHolderLabel?.hidden = false;
            }
        }
        else {
            
        }
    }
    
    func bulk() {
        
        bulkpostcnt = 0
        
        var timer:NSTimer = NSTimer.scheduledTimerWithTimeInterval(1   , target: self, selector: Selector("bulkPost"), userInfo: nil, repeats: true);
    }
    
    func bulkPost() {
        
        bulkpostcnt++
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        var s:String = "Post \(bulkpostcnt)"
        
        println(s)
        
        appDelegate.post(s) as (sucess:Bool,beaconId:String)?
        
//        for index in 1...10 {
//            
//            var s:String = "Post \(bulkpostcnt) ------ \(index) - \(NSDate())"
//            
//            println(s)
//            
//            appDelegate.post(s) as (sucess:Bool,beaconId:String)?
//        }
    }
    
    func post() {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if let postText = self.postTextView?.text {
            
            let result =  appDelegate.post(postText) as (sucess:Bool,beaconId:String)?
            
            if result!.sucess {
                //self.showAlert("Advertized Successfully", message: "\(result?.beaconId)")
                self.navigationController?.popViewControllerAnimated(true)
            }
            else {
                self.showAlert("Post Failed", message: "Please make sure there are no special characters in the post text!")
            }
            
        }
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
    
    func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().value
        return networkStatus != 0
    }
}


