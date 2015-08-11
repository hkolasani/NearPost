//
//  BeaconManager.swift
//  NearPost
//
//  Created by Hari Kolasani on 7/27/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

class BeaconManager:NSObject,CLLocationManagerDelegate,CBPeripheralManagerDelegate {

    let MAX_BEACON_MAJOR_MINOR_NUM:Int =  65534
    
    var peripheralManager:CBPeripheralManager?
    var beaconRegion:CLBeaconRegion?
    var locationManager: CLLocationManager?
    
    var previouslyRangedBeaconsSet:Set<String> = Set<String>()
    var rangedBeaconsSet:Set<String> = Set<String>()
  
    var currentYear:Int = 2015
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    let BEACON_UUID:NSUUID? = NSUUID(UUIDString:"ba5676a0-370a-11e5-a151-feff819cdc9f")
    let BEACON_IDENTIFIER:String = "com.nearpost.beacons"
    
    let rangedBeaconsAccessQueue = dispatch_queue_create("com.bluecloudsys.NearPost.RangedBeaconsSet", nil); //creates a serial queue
    
     override init() {
        
        super.init()
        
        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: date)
        self.currentYear = components.year
        
        self.initBeacon()
        
        //self.test()
    }
    
    func test() {
        
        var timer:NSTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("testAdvertize"), userInfo: nil, repeats: true);
        
    }
    
    func testAdvertize() {
        
        var rangedBeacons:[String] = [String]()
        
        for var i = 0; i < 1; i++ {
            rangedBeacons.append(self.getBeaconId(randomInt(0,max: MAX_BEACON_MAJOR_MINOR_NUM),minor:randomInt(0,max: MAX_BEACON_MAJOR_MINOR_NUM)))
        }
        
        dispatch_async(rangedBeaconsAccessQueue) {
            self.testGatherRangedBeacons(rangedBeacons)
        }
    }
    
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
    
    func startMonitoringForRegion() {
        
        self.beaconRegion = CLBeaconRegion(proximityUUID: self.BEACON_UUID,identifier: self.BEACON_IDENTIFIER)
        
        //beaconRegion.notifyEntryStateOnDisplay = true
        self.beaconRegion!.notifyOnEntry = true
        self.beaconRegion!.notifyOnExit = true
        
        locationManager = CLLocationManager()
        if(locationManager!.respondsToSelector("requestAlwaysAuthorization")) {
            locationManager!.requestAlwaysAuthorization()
        }
        
        locationManager!.delegate = self
        locationManager!.pausesLocationUpdatesAutomatically = false
        
        locationManager!.startMonitoringForRegion(beaconRegion)
        
        locationManager!.startRangingBeaconsInRegion(self.beaconRegion)
        
        locationManager!.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        
        self.sendLocalNotificationWithMessage("Found Conversations!")
        
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
            let reangedBeacon:CLBeacon = beacons[0] as! CLBeacon
            let rangedBeaconId:String = self.getBeaconId(reangedBeacon.major.integerValue,minor:reangedBeacon.minor.integerValue)
            self.sendLocalNotificationWithMessage("ranged :\(rangedBeaconId)")
            dispatch_async(rangedBeaconsAccessQueue) {
                self.gatherRangedBeacons(beacons as! [CLBeacon])
            }
        }
        else {
        }
    }
    
    func post(postText:String) -> (Bool,String)? {
        
        let majorInt:UInt16 = UInt16(randomInt(0,max: MAX_BEACON_MAJOR_MINOR_NUM))
        var minorInt:UInt16 = UInt16(randomInt(0,max: MAX_BEACON_MAJOR_MINOR_NUM))
        
        var beaconId:String =  self.getBeaconId(Int(majorInt),minor:Int(minorInt))
        
        var postBody:String = "\(beaconId)POSTTEXT:\(postText).USERTHUMB:\(appDelegate.userThumbURL)"
        
        let success = SFDCDataManager.postPost(postBody)
        
        if(success) {
            self.advertize(majorInt,minor:minorInt)
        }
        
        return (success,beaconId)
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
    
    func getRangedBeacons()->Set<String> {
        
        let beaconsSet:Set<String> = Set(self.rangedBeaconsSet.subtract(self.previouslyRangedBeaconsSet))
        
        self.initRangedBeacons()
        
        return beaconsSet
    }

    func gatherRangedBeacons(rangedBeacons:[CLBeacon]){
        
        for rangedBeacon in rangedBeacons {
            let rangedBeaconId:String = self.getBeaconId(rangedBeacon.major.integerValue,minor:rangedBeacon.minor.integerValue)
            self.rangedBeaconsSet.insert(rangedBeaconId)
        }
    }
    
    func initRangedBeacons() {
        
        self.previouslyRangedBeaconsSet = Set(self.rangedBeaconsSet)
        
        self.rangedBeaconsSet = Set<String>() //initialize
    }
    
    /************************** TEST POSTS GCD TEST ************************/
    func testGatherRangedBeacons(rangedBeacons:[String]){
        
        for rangedBeacon in rangedBeacons {
            self.rangedBeaconsSet.insert(rangedBeacon)
        }
    }
    /************************** TEST POSTS GCD TEST ************************/
    
    func showAlert(title:String,message:String) {
        
        var alertView = UIAlertView();
        alertView.addButtonWithTitle("OK");
        alertView.title = title;
        alertView.message = message;
        
        dispatch_async(dispatch_get_main_queue(), {
            alertView.show();
        })
    }
    
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
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}


