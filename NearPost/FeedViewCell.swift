//
//  FeedViewCell.swift
//  NearPost
//
//  Created by Hari Kolasani on 8/13/15.
//  Copyright (c) 2015 BlueCloud Systems. All rights reserved.
//

import Foundation

class FeedViewCell : UITableViewCell {
    
    @IBOutlet var userImageView: UIImageView?
    @IBOutlet var username: UILabel?
    @IBOutlet var when: UILabel?
    @IBOutlet var postText: UILabel?
    
    
    func populateCell(post: Post) {
    
        if let imageData = post.thumbnail {
            if let image = UIImage(data: imageData) {
                UIGraphicsBeginImageContext(CGSize(width: 44, height: 44))
                image.drawInRect(CGRectMake(0, 0, 44, 44))
                if let theImage = UIGraphicsGetImageFromCurrentImageContext() {
                    userImageView?.image = theImage
                }
                UIGraphicsEndImageContext();
            }
        }
   
        username!.text = post.createdBy
        
        if let timeago = post.created {
            when!.text = timeago
        }
        
        postText!.text = post.postText
        
        username?.font = UIFont(name: "Avenir-Black", size: 14)
        when?.font = UIFont(name: "Avenir-Light", size: 12)
        postText?.font = UIFont(name: "Avenir-Book", size: 15)
        
    }
}