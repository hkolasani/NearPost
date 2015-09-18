//
//  SFDCSettings.swift
//  NearPost
//
//  Created by Hari Kolasani on 5/27/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation

class SFDCSettings:NSObject {
    
    var clientId:String = "XXXXXXXXXXXXXXXXXX"  //NearPost remote App on SFDC
    var callbackURL:String = "XXXXXXX://"
    var loginHost:String = "success.salesforce.com"
    var scopes:Set<String> = ["web","visualforce","api"]
    var nearPostGroupId:String = "XXXXXXXXX"   //Near Post Group Id
    var communityId:String = "XXXXXXXXXXX"   //Id of the Salesfoce Success Community
    var communitiesURL:String = "https://success.salesforce.com/services/data/v34.0/connect/communities"
    var hostURL:String = "https://success.salesforce.com/services/data/v34.0"
    
    override init() {
        
        super.init()
        
        //get the values from app settings
        
    }

}
