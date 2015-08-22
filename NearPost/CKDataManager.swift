//
//  CKDataManager.swift
//  NearPost
//
//  Created by Hari Kolasani on 8/20/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class CKManager {
    
    var publicDatabase:CKDatabase
    var privateDatabase:CKDatabase
    var defaultContainer:CKContainer
    var counter:Int = 10
    
    init() {
        
        defaultContainer = CKContainer.defaultContainer()
        
        publicDatabase = defaultContainer.publicCloudDatabase
        privateDatabase = defaultContainer.privateCloudDatabase
    }
    
    func getPostIds(beaconIds:[String],completionHandler:([String]!,NSError!)->Void) {
        
        if !self.hasConnectivity() {
            let erroDesc = "No Internet Connection!"
            dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,NSError(domain: "err", code: 999, userInfo: [NSLocalizedFailureReasonErrorKey : erroDesc]))}
        }
        
        let predicate = NSPredicate(format: "%K IN %@","BeaconId",beaconIds)
        
        let query = CKQuery(recordType: "Post", predicate: predicate)
        
        publicDatabase.performQuery(query,inZoneWithID: nil) {records,error in
            if (error != nil) {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,error)}
            } else {
                var postIds:[String] = [String]()
                for record : AnyObject in records {
                    if let postId = (record as! CKRecord).objectForKey("PostId") as! String? {
                        postIds.append(postId)
                    }
                }
                dispatch_async(dispatch_get_main_queue()) {completionHandler(postIds,nil)}
            }
        }
    }
 
    func createPost(beaconId:String,postId:String,completionHandler:(CKRecord!,NSError!)->Void)  {
        
        if !self.hasConnectivity() {
            let erroDesc = "No Internet Connection!"
            dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,NSError(domain: "err", code: 999, userInfo: [NSLocalizedFailureReasonErrorKey : erroDesc]))}
        }
        
        var postRecord = CKRecord(recordType: "Post")

        postRecord.setValue(beaconId, forKey:"BeaconId")
        postRecord.setValue(postId, forKey:"PostId")

        publicDatabase.saveRecord(postRecord) {savedRecord,error in
            if (error != nil)   {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,error)}
            } else {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(savedRecord,nil)}
            }
        }
    }
    
    func requestDiscoverabilityPermission(completionHandler:(Bool,NSError!)->Void) {
        
        defaultContainer.requestApplicationPermission(CKApplicationPermissions.PermissionUserDiscoverability) {applicationPermissionStatus,error in
            if ((error) != nil) {
                // In your app, handle this error really beautifully.
                println(error?.localizedDescription)
                dispatch_async(dispatch_get_main_queue()) {completionHandler(false,error)}
            } else {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(applicationPermissionStatus == CKApplicationPermissionStatus.Granted,nil)}
            }
        }
    }
    
    func fetchUserInfo(completionHandler:(CKDiscoveredUserInfo!,NSError!)->Void) {
        
        if !self.hasConnectivity() {
            let erroDesc = "No Internet Connection!"
            dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,NSError(domain: "err", code: 999, userInfo: [NSLocalizedFailureReasonErrorKey : erroDesc]))}
        }
        
        defaultContainer.fetchUserRecordIDWithCompletionHandler() {userRecrodId,error in
            if (error != nil)   {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,error)}
            } else {
                //println("user recordId \((userRecrodId! as CKRecordID).recordName)")
                self.defaultContainer.discoverUserInfoWithUserRecordID(userRecrodId) {discoverableUserInfo,error in
                    //self.defaultContainer.discoverUserInfoWithEmailAddress("hkolasani@bluecloudsystems.com") {discoverableUserInfo,error in
                    if ((error) != nil) {
                        dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,error)}
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {completionHandler(discoverableUserInfo,nil)}
                    }
                }
            }
        }
    }
    
    func fetchUserRecordID(completionHandler:(CKRecordID!,NSError!)->Void) {
        
        if !self.hasConnectivity() {
            let erroDesc = "No Internet Connection!"
            dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,NSError(domain: "err", code: 999, userInfo: [NSLocalizedFailureReasonErrorKey : erroDesc]))}
        }
        
        defaultContainer.fetchUserRecordIDWithCompletionHandler() {userRecrodId,error in
            if (error != nil)   {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,error)}
            } else {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(userRecrodId,nil)}
            }
        }
    }
    
    func fetchUserRecord(completionHandler:(CKRecord!,NSError!)->Void) {
        
        if !self.hasConnectivity() {
            let erroDesc = "No Internet Connection!"
            dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,NSError(domain: "err", code: 999, userInfo: [NSLocalizedFailureReasonErrorKey : erroDesc]))}
        }
        
        defaultContainer.fetchUserRecordIDWithCompletionHandler() {userRecrodId,error in
            if (error != nil)   {
                dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,error)}
            } else {
                //println("user recordId \((userRecrodId as CKRecordID).recordName)")
                self.publicDatabase.fetchRecordWithID(userRecrodId) {userRecord,error in
                    if ((error) != nil) {
                        dispatch_async(dispatch_get_main_queue()) {completionHandler(nil,error)}
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {completionHandler(userRecord,nil)}
                    }
                }
            }
        }
    }
    
    func hasConnectivity() -> Bool {
        let reachability: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachability.currentReachabilityStatus().value
        return networkStatus != 0
    }
}
