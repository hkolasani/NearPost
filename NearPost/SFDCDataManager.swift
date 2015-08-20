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
        
        println(accessToken)
        
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
    
    class func testFetchPosts(beacons:[String])-> [Post] {
        
        var newPosts:[Post] = [Post]()
        
        for beacon in beacons {
            var post:Post = Post()
            post.postBody = "New Post from \(beacon)"
            newPosts.append(post)
        }
        
        return newPosts
    }

    class func getPostById(postId:String)-> Post? {
        
        var requestURL:String = "\(SFDC_SETTINGS.hostURL)/sobjects/CollaborationGroupFeed/\(postId)"
        
        let accessToken = getAccessToken()
        
        println(accessToken)
        
        if let responseData:NSData = SFDCDataManager.sendSyncRequest(requestURL, accessToken:accessToken) {
            if let dataString = NSString(data: responseData, encoding:NSUTF8StringEncoding) {
                println(dataString)
            }
        }
        
        return Post()
    }

    class func fetchPosts(beacons:[String])-> [Post] {
        
        var queryString:String = buildFeedQueryString(beacons)
        
        queryString = queryString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        
        var requestURL:String = "\(SFDC_SETTINGS.communitiesURL)/\(SFDC_SETTINGS.communityId)/chatter/feeds/record/\(SFDC_SETTINGS.nearPostGroupId)/feed-elements?q=\(queryString)"
        
        let accessToken = getAccessToken()
        
        println(accessToken)
        
        if let responseData:NSData = SFDCDataManager.sendSyncRequest(requestURL, accessToken:accessToken) {
            return parseFetchResults(responseData)
        }
        else {
            return [Post]()
        }
    }
    
    class func parseFetchResults(responseData:NSData?) -> [Post] {
        
        var posts:[Post] = [Post]()
        
        if(responseData != nil) {
            
            let dataString = NSString(data: responseData!, encoding:NSUTF8StringEncoding)
            
            if dataString != nil {
                
                println(dataString)
                
                if (dataString!.lowercaseString.rangeOfString("\"errorcode\":") == nil) {
                    
                    var parseError: NSError?
                    
                    let parsedObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(responseData!,options: NSJSONReadingOptions.AllowFragments,error:&parseError)
                    
                    if let results = parsedObject as? NSDictionary {
                    
                        if let elements = results["elements"] as? NSArray {
                         
                            for element in elements {
                            
                                var post:Post = buildPost(element as! NSDictionary)
                            
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
    
    class func postPost(postBody:String)->Bool {
        
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
                return false
            }
            else {
                if let responseDataString = NSString(data: responseData, encoding:NSUTF8StringEncoding) {
                    if (responseDataString.lowercaseString.rangeOfString("errorcode") != nil) {
                        //println(responseDataString)
                        return false
                    }
                    else {
                        if let post = getCreatedPost(responseData) {
                            if let post = getPostById(post.postId!) {
                                println("Got it")
                            }
                        }
                    }
                }
                else {
                    return false
                }
            }
        }
        
        return true
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

        return credentials.accessToken
    }
    
    class func buildBeaconsPred(beacons:[String])->String {
        
        var pred:String = "{"
        
        var cnt:Int = 0
        
        for beacon in beacons {
            if(cnt > 0) {
                 pred = "\(pred) OR "
            }
            pred = "\(pred)\(beacon)"
            
            cnt++
        }
        
        pred = "\(pred)} "
        
        return pred
    }
    
    class func buildFeedQueryString(beacons:[String])->String {
        
        var pred:String = ""
        
        var cnt:Int = 0
        
        for beacon in beacons {
            if(cnt > 0) {
                pred = "\(pred) OR "
            }
            pred = "\(beacon)*"
            
            cnt++
        }
        
        return pred
    }
    
    class func buildPost(element:NSDictionary) -> Post {
    
        var post:Post = Post()
        post.postBody = ""
        post.postText = ""
       
        post.postId = element["id"] as? String
        post.created = element["relativeCreatedDate"] as? String
        
        if let actor = element["actor"] as? NSDictionary {
            post.createdBy = actor["displayName"] as? String
            post.createdById = actor["id"] as? String
            if let photoDict = actor["photo"] as? NSDictionary {
                post.thumbURL = photoDict["smallPhotoUrl"] as? String
            }
        }
        
        if let bodyDict = element["body"] as? NSDictionary {
            if let postBody:String = bodyDict["text"]  as? String {
                post.postBody = postBody
                if let rangeOfPost = postBody.rangeOfString("POSTTEXT:") {
                    post.beaconId = postBody.substringToIndex(rangeOfPost.startIndex)
                    post.postText = postBody.substringFromIndex(rangeOfPost.endIndex)
                }
            }
        }
        
        return post
    }
}
