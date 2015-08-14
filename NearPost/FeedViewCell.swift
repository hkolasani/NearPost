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
        let str =  self.timeAgoSinceDate(post.dateCreated!,numericDates:false)
        when!.text = str
        postText!.text = post.postText
        
        username?.font = UIFont(name: "Avenir-Black", size: 14)
        when?.font = UIFont(name: "Avenir-Light", size: 12)
        postText?.font = UIFont(name: "Avenir-Book", size: 15)
        
    }
    
    func timeAgoSinceDate(date:NSDate, numericDates:Bool) -> String {
        let calendar = NSCalendar.currentCalendar()
        let unitFlags = NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitDay | NSCalendarUnit.CalendarUnitWeekOfYear | NSCalendarUnit.CalendarUnitMonth | NSCalendarUnit.CalendarUnitYear | NSCalendarUnit.CalendarUnitSecond
        let now = NSDate()
        let earliest = now.earlierDate(date)
        let latest = (earliest == now) ? date : now
        let components:NSDateComponents = calendar.components(unitFlags, fromDate: earliest, toDate: latest, options: nil)
        
        if (components.year >= 2) {
            return "\(components.year) years ago"
        } else if (components.year >= 1){
            if (numericDates){
                return "1 year ago"
            } else {
                return "Last year"
            }
        } else if (components.month >= 2) {
            return "\(components.month) months ago"
        } else if (components.month >= 1){
            if (numericDates){
                return "1 month ago"
            } else {
                return "Last month"
            }
        } else if (components.weekOfYear >= 2) {
            return "\(components.weekOfYear) weeks ago"
        } else if (components.weekOfYear >= 1){
            if (numericDates){
                return "1 week ago"
            } else {
                return "Last week"
            }
        } else if (components.day >= 2) {
            return "\(components.day) days ago"
        } else if (components.day >= 1){
            if (numericDates){
                return "1 day ago"
            } else {
                return "Yesterday"
            }
        } else if (components.hour >= 2) {
            return "\(components.hour) hours ago"
        } else if (components.hour >= 1){
            if (numericDates){
                return "1 hour ago"
            } else {
                return "An hour ago"
            }
        } else if (components.minute >= 2) {
            return "\(components.minute) minutes ago"
        } else if (components.minute >= 1){
            if (numericDates){
                return "1 minute ago"
            } else {
                return "A minute ago"
            }
        } else if (components.second >= 3) {
            return "\(components.second) seconds ago"
        } else {
            return "Just now"
        }
        
    }
}