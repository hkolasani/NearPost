//
//  AppDelegate.swift
//  NearPost
//
//  Created by Hari Kolasani on 5/23/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,SFAuthenticationManagerDelegate,SFUserAccountManagerDelegate,CLLocationManagerDelegate,CBPeripheralManagerDelegate {

    var window: UIWindow?
    
    var navController:UINavigationController?
    var feedViewController:FeedViewController?
    
    var userThumbURL:String = ""
    
    let MAX_BEACON_MAJOR_MINOR_NUM:Int =  65534
    
    var peripheralManager:CBPeripheralManager?
    var beaconRegion:CLBeaconRegion?
    var locationManager: CLLocationManager?
    
    var previouslyGatheredBeaconsSet:Set<String> = Set<String>()
    var previouslyRangedBeaconsSet:Set<String> = Set<String>()
    var currentlyRangedBeaconsSet:Set<String> = Set<String>()
    var allRangedBeaconsSet:Set<String> = Set<String>()
    
    var currentYear:Int = 2015
    
    let BEACON_UUID:NSUUID? = NSUUID(UUIDString:"ba5676a0-370a-11e5-a151-feff819cdc9f")
    let BEACON_IDENTIFIER:String = "com.nearpost.beacons"
    
    let rangedBeaconsAccessQueue = dispatch_queue_create("com.bluecloudsys.NearPost.RangedBeaconsSet", nil); //creates a serial queue
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        if !self.hasConnectivity() {
            self.showAlert("Warning!", message: "NearPost requires Internet Connection to function!")
        }
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: date)
        self.currentYear = components.year
        
        // Override point for customization after application launch.
        if(application.respondsToSelector("registerUserNotificationSettings:")) {
            application.registerForRemoteNotifications() //this is for CloudKit Subscriptions
            let settings = UIUserNotificationSettings(forTypes:.Alert, categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Override point for customization after application launch.
        
        SFAuthenticationManager.sharedManager().addDelegate(self)
        SFUserAccountManager.sharedInstance().addDelegate(self)
        
        var sfdcSettings:SFDCSettings = SFDCSettings()
        
        SFUserAccountManager.sharedInstance().scopes = sfdcSettings.scopes
        SFUserAccountManager.sharedInstance().loginHost = sfdcSettings.loginHost
        SFUserAccountManager.sharedInstance().oauthClientId = sfdcSettings.clientId
        SFUserAccountManager.sharedInstance().oauthCompletionUrl = sfdcSettings.callbackURL
        
        self.initBeacon()
        
        self.startLookingForbeacons()
        
        return true
    }
    
    func initializeAppViewState() {
        
        var initialViewController: InitViewController? = InitViewController(nibName:"InitViewController", bundle: nil)
        
        self.window?.rootViewController = initialViewController
        self.window?.backgroundColor = UIColor.whiteColor()
        self.window?.makeKeyAndVisible()
    }
    
    func setupRootViewController() {
        
        let storyboard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
        //var feedViewController:FeedViewController = storyboard.instantiateViewControllerWithIdentifier("FeedView") as! FeedViewController
        
        self.navController =  storyboard.instantiateViewControllerWithIdentifier("NavController") as? UINavigationController
        
        if let viewControllers = self.navController!.viewControllers {
            self.feedViewController = viewControllers.last as? FeedViewController
        }
        
        self.window?.rootViewController = self.navController
    }

    //********************************************** SFDC *************************************************//
    
    func relogin(loggedIn:(Void)->(Void)) {
        
        SFAuthenticationManager.sharedManager().loginWithCompletion( { oAuthInfo in
            loggedIn()
            }, failure: { oAuthInfo,error in
                SFAuthenticationManager.sharedManager().logout()
        })
    }
    
    func loginToSFDC(loggedIn:(Void)->(Void)) {
        
        
        SFAuthenticationManager.sharedManager().loginWithCompletion( { oAuthInfo in
            
            let userInfoDict = SFDCDataManager.getUserInfo()
            let photosDict:NSDictionary = userInfoDict.objectForKey("photos") as! NSDictionary
            self.userThumbURL  = photosDict.objectForKey("thumbnail") as! String

                println(SFDCDataManager.getAccessToken())
            
                let storyboard:UIStoryboard = UIStoryboard(name:"Main", bundle:nil)
                //var feedViewController:FeedViewController = storyboard.instantiateViewControllerWithIdentifier("FeedView") as! FeedViewController
            
                self.navController =  storyboard.instantiateViewControllerWithIdentifier("NavController") as? UINavigationController
            
                if let viewControllers = self.navController!.viewControllers {
                    self.feedViewController = viewControllers.last as? FeedViewController
                }

                loggedIn()
            
            }, failure: { oAuthInfo,error in
                SFAuthenticationManager.sharedManager().logout()
        })
    }
    
    func userAccountManager(userAccountManager: SFUserAccountManager!, didSwitchFromUser fromUser: SFUserAccount!, toUser: SFUserAccount!) {
        //self.showAlert("Info", message: "Login Host Changed")
        self.loginToSFDC {
            self.setupRootViewController()
        }
    }
    
    func authManagerDidLogout(manager: SFAuthenticationManager!) {
        //self.showAlert("Info", message: "Logged Out")
        self.loginToSFDC {
            self.setupRootViewController()
        }
    }
 
    
    //********************************************** BEACON *************************************************//
    
    func initBeacon() {
        
        let options: Dictionary<NSString, AnyObject> = [ CBPeripheralManagerOptionShowPowerAlertKey: true ]
        self.peripheralManager =  CBPeripheralManager(delegate:self,queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),options:options)
    }
    
    func peripheralManagerDidUpdateState(peripheralMgr: CBPeripheralManager!) {
        
        self.peripheralManager = peripheralMgr
    }
    
    func stopMonitoringForRegion() {
        
        self.locationManager!.stopMonitoringForRegion(beaconRegion)
    }
    
    func startLookingForbeacons() {
        
        self.beaconRegion = CLBeaconRegion(proximityUUID: self.BEACON_UUID,identifier: self.BEACON_IDENTIFIER)
        
        //beaconRegion.notifyEntryStateOnDisplay = true
        self.beaconRegion!.notifyOnEntry = true
        self.beaconRegion!.notifyOnExit = true
        
        locationManager = CLLocationManager()
        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager!.requestAlwaysAuthorization()
        }
        
        locationManager?.delegate = self
        locationManager?.pausesLocationUpdatesAutomatically = false
        
        locationManager?.startMonitoringForRegion(beaconRegion)
        
        locationManager?.startRangingBeaconsInRegion(self.beaconRegion)
        
        locationManager?.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        
        self.sendLocalNotificationWithMessage("Found NearPost Beacons!")
        
        self.locationManager!.startRangingBeaconsInRegion(self.beaconRegion)
    }
    
    func startRanging() {
        
        self.locationManager!.startRangingBeaconsInRegion(self.beaconRegion)
    }
    
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        
        self.locationManager!.stopRangingBeaconsInRegion(self.beaconRegion)
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        
        if(beacons.count > 0) {
            dispatch_async(rangedBeaconsAccessQueue) {
                self.gatherRangedBeacons(beacons as! [CLBeacon])
            }
        }
        else {
        }
    }
    
    func post(postText:String) -> (String,String?)? {
        
        let majorInt:UInt16 = UInt16(randomInt(0,max: MAX_BEACON_MAJOR_MINOR_NUM))
        var minorInt:UInt16 = UInt16(randomInt(0,max: MAX_BEACON_MAJOR_MINOR_NUM))
        
        var beaconId:String =  self.getBeaconId(Int(majorInt),minor:Int(minorInt))

        var postBody:String = "\(beaconId)POSTTEXT:\(postText).USERTHUMB:\(self.userThumbURL)"
        
        var newPostId:String?
        
        if let postId = SFDCDataManager.postPost(postBody) {
            
            newPostId = postId
            
            var ckManager:CKManager = CKManager()
                
            ckManager.createPost(beaconId,postId:postId) {savedRecord,error in
                
                if (error == nil) {
                        self.advertize(majorInt,minor:minorInt)
                }
                else {
                    newPostId = nil
                    println("CKRecord Create Error: \(error.localizedDescription)") 
                }
            }
        }
        
        return (beaconId,newPostId)
    }
    
    func stopAdvertizing() {
        
        self.peripheralManager!.stopAdvertising()
    }
    
    func advertize(major:UInt16,minor:UInt16) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if self.peripheralManager!.state != CBPeripheralManagerState.PoweredOn {
            self.showAlert("Warning!", message: "Please turn on Bluetooth to allow Advertizing of the Post")
            return
        }
        
        self.peripheralManager!.stopAdvertising()
        
        var region:CLBeaconRegion  = CLBeaconRegion(proximityUUID: self.BEACON_UUID, major:major, minor:minor, identifier: self.BEACON_IDENTIFIER)
        var peripheralData =  region.peripheralDataWithMeasuredPower(-59) as [NSObject : AnyObject];
        
        self.peripheralManager!.startAdvertising(peripheralData);
    }
    
    func gatherRangedBeacons(rangedBeacons:[CLBeacon]){
        
        for rangedBeacon in rangedBeacons {
            let rangedBeaconId:String = self.getBeaconId(rangedBeacon.major.integerValue,minor:rangedBeacon.minor.integerValue)
            self.currentlyRangedBeaconsSet.insert(rangedBeaconId)
        }
        
        let newlyRangedBeaconsSet:Set<String> = Set(self.currentlyRangedBeaconsSet.subtract(self.previouslyGatheredBeaconsSet))
        
        self.previouslyGatheredBeaconsSet = Set(self.currentlyRangedBeaconsSet)
        
        if (newlyRangedBeaconsSet.count > 0) {
            if (newlyRangedBeaconsSet.count > 1) {
                self.sendLocalNotificationWithMessage("\(newlyRangedBeaconsSet.count) New Posts!.")
            }
            else {
                self.sendLocalNotificationWithMessage("New Post!")
            }
        }
    }
    
    func getRangedBeacons()->Set<String> {
        
        let beaconsSet:Set<String> = Set(self.currentlyRangedBeaconsSet.subtract(self.previouslyRangedBeaconsSet))
        
        self.previouslyRangedBeaconsSet = Set(self.currentlyRangedBeaconsSet)
        
        self.currentlyRangedBeaconsSet = Set<String>() //initialize
        
        return beaconsSet
    }
    
    
    //********************************************** APP DELEGATES *************************************************//
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        self.feedViewController?.stopTimer()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
    
    //********************************************** UTILITY *************************************************//
    
    func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
    
    func getBeaconId(major:Int,minor:Int)->String {
        
        return "\(major)9999999\(minor)\(self.currentYear)"
    }
    
    func sendLocalNotificationWithMessage(message: String!) {
        let notification:UILocalNotification = UILocalNotification()
        notification.alertBody = message
    
        //notification.soundName = "tos_beep.caf";
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
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
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().value
        return networkStatus != 0
    }
    
    func applicationDidReceiveMemoryWarning(application: UIApplication) {
        //NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
}

