//
//  SFDCDataManager.swift
//  NearPost
//
//  Created by Hari Kolasani on 5/27/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation

class SFDCDataManager {
    
    static var SFDC_SETTINGS:SFDCSettings = SFDCSettings()
    
    class func login(handler:(Bool,NSError!)->Void) {
        
        SFUserAccountManager.sharedInstance().oauthClientId = SFDC_SETTINGS.clientId
        SFUserAccountManager.sharedInstance().oauthCompletionUrl = SFDC_SETTINGS.callbackURL
        SFUserAccountManager.sharedInstance().loginHost = SFDC_SETTINGS.loginHost;
        
        SFAuthenticationManager.sharedManager().loginWithCompletion( { oAuthInfo in
            handler(true,nil)
            }, failure: { oAuthInfo,error in
                handler(false,error)
        })
    }
    
    class func runQuery(query:String,handler:([Dictionary<String,AnyObject>]!,NSError!)->Void) {
        
        SFRestAPI.sharedInstance().performSOQLQuery(query, failBlock: { error in
            handler(nil,error)
            }) { queryResponse in
                handler(queryResponse["records"]! as? [Dictionary<String,AnyObject>] ,nil)
        }
    }
    
    class func getUserThumbnail()->NSData? {
        
        let userInfoDict = SFDCDataManager.getUserInfo()
        
        let photosDict:NSDictionary = userInfoDict.objectForKey("photos") as! NSDictionary
        
        let thumbURL:String  = photosDict.objectForKey("thumbnail") as! String
        
        let accessToken = userInfoDict.objectForKey("accesstoken") as! String
        
        return SFDCDataManager.sendSyncRequest(thumbURL, accessToken:accessToken)
    }
    
    class func getImage(url:String)->NSData? {
        
        let accessToken = getAccessToken()
        
        return SFDCDataManager.sendSyncRequest(url, accessToken:accessToken)
    }
   
    class func getUserPicture()-> NSData? {
        
        let userInfoDict = SFDCDataManager.getUserInfo()
        
        let photosDict:NSDictionary = userInfoDict.objectForKey("photos") as! NSDictionary
        
        let picURL:String  = photosDict.objectForKey("picture") as! String
        
        let accessToken = getAccessToken()
        
        println(accessToken)
        
        return SFDCDataManager.sendSyncRequest(picURL, accessToken:accessToken)
    }
    
    class func getPostById(postId:String)-> Post? {
        
        var requestURL:String = "\(SFDC_SETTINGS.hostURL)/sobjects/CollaborationGroupFeed/\(postId)"
        
        let accessToken = getAccessToken()
        
        if let responseData:NSData = SFDCDataManager.sendSyncRequest(requestURL, accessToken:accessToken) {
            if let dataString = NSString(data: responseData, encoding:NSUTF8StringEncoding) {
                println(dataString)
            }
        }
        
        return Post()
    }
    
    class func fetchPosts(beacons:[String])-> [Post] {
        
       var queryString:String = "Select Id,InsertedById,InsertedBy.Name,Body, Title,Type,CreatedDate From FeedItem  where Id IN "

        queryString = "\(queryString) \(buildInClause(beacons))"
        
        queryString = queryString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        
        var requestURL:String = "\(SFDC_SETTINGS.hostURL)/query?q=\(queryString)"
        
        let accessToken = getAccessToken()
        
        if let responseData:NSData = SFDCDataManager.sendSyncRequest(requestURL, accessToken:accessToken) {
            return parseQueryResults(responseData)
        }
        else {
            return [Post]()
        }
    }

    
    class func parseQueryResults(responseData:NSData?) -> [Post] {
        
        var posts:[Post] = [Post]()
        
        if(responseData != nil) {
            
            let dataString = NSString(data: responseData!, encoding:NSUTF8StringEncoding)
            
            if dataString != nil {
                
                println(dataString)
                
                if (dataString!.lowercaseString.rangeOfString("\"errorcode\":") == nil) {
                    
                    var parseError: NSError?
                    
                    let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData!,options: NSJSONReadingOptions.AllowFragments,error:&parseError)
                    
                    if let results = parsedObject as? NSDictionary {
                        
                        if let records = results["records"] as? NSArray {
                            
                            for record in records {
                                
                                var post:Post = buildPost(record as! NSDictionary)
                                
                                posts.append(post)
                            }
                        }
                    }
                    else {
                        println("JSON Parse Error")
                    }
                }
            }
        }
        
        return posts
    }
    
    class func postPost(postBody:String)->String? {
        
        var postId:String?
        
        let accessToken = getAccessToken()

        var postRequestBody:String =  "{\"body\" : {\"messageSegments\" : [{\"type\" : \"Text\",\"text\" : \"\(postBody)\"}]},\"feedElementType\" : \"FeedItem\",\"subjectId\" : \"\(SFDC_SETTINGS.nearPostGroupId)\"}"
        
        var postURL:String = "\(SFDC_SETTINGS.communitiesURL)/\(SFDC_SETTINGS.communityId)/chatter/feed-elements"
        
        var request = NSMutableURLRequest(URL: NSURL(string:postURL)!)
        var response: NSURLResponse?
        var error:NSError?
        
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("OAuth \(accessToken)", forHTTPHeaderField:"Authorization")
        
        request.HTTPBody =  (postRequestBody as NSString).dataUsingEncoding(NSUTF8StringEncoding)
        
        if let responseData:NSData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error:&error) {
        
            if error != nil {
                println(error?.description)
            }
            else {
                if let responseDataString = NSString(data: responseData, encoding:NSUTF8StringEncoding) {
                    if (responseDataString.lowercaseString.rangeOfString("errorcode") != nil) {
                        println(responseDataString)
                    }
                    else {
                        if let post = getCreatedPost(responseData) {
                            if let post = getPostById(post.postId!) {
                                postId = post.postId
                            }
                        }
                    }
                }
            }
        }
        
        return postId
    }
    
    class func getCreatedPost(newPostResponseData:NSData)->Post? {
        
        var parseError: NSError?
        
        var post:Post?
        
        let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(newPostResponseData,options: NSJSONReadingOptions.AllowFragments,error:&parseError)
        
        if let element = parsedObject as? NSDictionary {
            post = buildPost(element)
        }
        else {
            println("JSON Parse Error")
        }
        
        return post
    }

    class func sendSyncRequest(urlString:String,accessToken:String)->NSData? {
        
        var request = NSMutableURLRequest(URL: NSURL(string:urlString)!)
        var response: NSURLResponse?
        var error:NSError?
        
        request.HTTPMethod = "GET"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "content-type")
        request.setValue("OAuth \(accessToken)", forHTTPHeaderField:"Authorization")
        
        return NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error:&error)
    }
    
    class func getUserInfo()-> NSDictionary {
        
        let accountManager:SFUserAccountManager = SFUserAccountManager.sharedInstance()
        
        let currentUser:SFUserAccount = SFUserAccountManager.sharedInstance().currentUser
        
        let idData:SFIdentityData = currentUser.idData
        
        let credentials:SFOAuthCredentials = currentUser.credentials
      
        let currentUserIdentity:SFUserAccountIdentity = SFUserAccountManager.sharedInstance().currentUserIdentity;
        
        var userInfoDict:NSMutableDictionary = NSMutableDictionary(dictionary:idData.dictRepresentation)
        
        return userInfoDict
    }
    
    
    class func getAccessToken()->String {
        
        let sfCoordinator:SFOAuthCoordinator = SFRestAPI.sharedInstance().coordinator
        
        let credentials:SFOAuthCredentials  = sfCoordinator.credentials
        
        println(credentials.accessToken)

        return credentials.accessToken
    }
    
    class func buildInClause(beacons:[String])->String {
        
        var pred:String = " ("
        
        var cnt:Int = 0
        
        for beacon in beacons {
            if(cnt > 0) {
                pred = "\(pred) , "
            }
            pred = "\(pred)\(beacon)"
            
            cnt++
        }
        
        pred = "\(pred) ) "
        
        return pred
    }

    class func buildPost(row:NSDictionary) -> Post {
        
        var post:Post = Post()
        post.postBody = ""
        post.postText = ""
        
        post.postId = row["Id"] as? String
        
        if let dateStr = row["CreatedDate"] as? String {
            if(count(dateStr) > 19) {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                dateFormatter.timeZone = NSTimeZone(name:"GMT")
                let index: String.Index = advance(dateStr.startIndex, 19)
                let dateSubStr = dateStr.substringToIndex(index)
                post.dateCreated = dateFormatter.dateFromString(dateSubStr)
            }
        }
        
        if let createdByDict = row["CreatedBy"] as? NSDictionary {
            post.createdBy = createdByDict["Name"] as? String
        }
        
        if let createdById = row["CreatedById"] as? String {
            post.createdById = createdById
        }
        
        if let postBody:String = row["Body"]  as? String {
            post.postBody = postBody
            if let rangeOfPost = postBody.rangeOfString("POSTTEXT:") {
                post.beaconId = postBody.substringToIndex(rangeOfPost.startIndex)
                var pBody:String? = postBody.substringFromIndex(rangeOfPost.endIndex)
                if pBody != nil {
                    if let rangeOfT = pBody!.rangeOfString("USERTHUMB:",options: .BackwardsSearch) {
                        post.postText = pBody!.substringToIndex(rangeOfT.startIndex)
                    }
                }
            }
            if let rangeOfThumb:Range = postBody.rangeOfString("USERTHUMB:",options: .BackwardsSearch) {
                post.thumbURL = postBody.substringFromIndex(rangeOfThumb.endIndex)
            }
        }
        
        return post
    }
}
