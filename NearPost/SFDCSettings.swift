//
//  SFDCSettings.swift
//  DreamBook
//
//  Created by Hari Kolasani on 5/27/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation

class SFDCSettings:NSObject {
    
    var clientId:String = "3MVG9yZ.WNe6byQDOL4KPtPTJwdTmJbYNVElnSvWenE9FLSE_E7PHcg2oe.LsdyBlX94H5.uxW28uRPiH1X8K"  //NearPost remote App on SFDC
    var callbackURL:String = "nearpost://"
    var loginHost:String = "success.salesforce.com"
    var scopes:Set<String> = ["web","visualforce","api"]
    var nesrPostGroupId:String = "0F930000000blOE"   //Near Post Group Id
    var communityId:String = "0DB30000000072LGAQ"   //Id of the Salesfoce Success Community
    var apiURL:String = "https://success.salesforce.com/services/data/v34.0"
    
    override init() {
        
        super.init()
        
        //get the values from app settings
        
    }

}
