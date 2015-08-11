//
//  AppDelegate.swift
//  DreamBook
//
//  Created by Hari Kolasani on 5/23/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,SFAuthenticationManagerDelegate,SFUserAccountManagerDelegate {

    var window: UIWindow?
    
    var beaconManager:BeaconManager?
    
    var userThumbURL:String = ""
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        //TODO: Intiialize App Settings.
        
        self .initializeAppViewState()
        
        // Override point for customization after application launch.
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            application.registerForRemoteNotifications() //this is for CloudKit Subscriptions
            let settings = UIUserNotificationSettings(forTypes:.Alert, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
         application.registerForRemoteNotifications()
        
        beaconManager = BeaconManager()
        
        // Override point for customization after application launch.
        
        SFAuthenticationManager.sharedManager().addDelegate(self)
        SFUserAccountManager.sharedInstance().addDelegate(self)
        
        var sfdcSettings:SFDCSettings = SFDCSettings()
        
        SFUserAccountManager.sharedInstance().scopes = sfdcSettings.scopes
        SFUserAccountManager.sharedInstance().loginHost = sfdcSettings.loginHost
        SFUserAccountManager.sharedInstance().oauthClientId = sfdcSettings.clientId
        SFUserAccountManager.sharedInstance().oauthCompletionUrl = sfdcSettings.callbackURL
        
        self.loginToSFDC()
        
        return true
    }
    
    func initializeAppViewState() {
        
        var initialViewController: InitViewController? = InitViewController(nibName:"InitViewController", bundle: nil)
        
        self.window?.rootViewController = initialViewController
        self.window?.backgroundColor = UIColor.whiteColor()
        self.window?.makeKeyAndVisible()
    }
    
    func loginToSFDC() {
        
        SFAuthenticationManager.sharedManager().loginWithCompletion( { oAuthInfo in
            
            let userInfoDict = SFDCDataManager.getUserInfo()
            let photosDict:NSDictionary = userInfoDict.objectForKey("photos") as! NSDictionary
            self.userThumbURL  = photosDict.objectForKey("thumbnail") as! String
            
            println(SFDCDataManager.getAccessToken())
            
            self.beaconManager!.startMonitoringForRegion()

            self.setupRootViewController()
            
            }, failure: { oAuthInfo,error in
                SFAuthenticationManager.sharedManager().logout()
        })
    }
    
    func setupRootViewController() {
       
        let storyboard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        //var feedViewController:FeedViewController = storyboard.instantiateViewControllerWithIdentifier("FeedView") as! FeedViewController
        
        var navController:UINavigationController =  storyboard.instantiateViewControllerWithIdentifier("NavController") as! UINavigationController
        
        self.window?.rootViewController = navController
    }
    
    func userAccountManager(userAccountManager: SFUserAccountManager!, didSwitchFromUser fromUser: SFUserAccount!, toUser: SFUserAccount!) {
        //self.showAlert("Info", message: "Login Host Changed")
        self.loginToSFDC()
    }
    
    func authManagerDidLogout(manager: SFAuthenticationManager!) {
        //self.showAlert("Info", message: "Logged Out")
        self.loginToSFDC()
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

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        self.beaconManager!.stopMonitoringForRegion()
        
        self.beaconManager!.startMonitoringForRegion()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

