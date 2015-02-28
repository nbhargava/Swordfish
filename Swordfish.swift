//
//  Swordfish.swift
//
//  Created by Nikhil on 2/8/15.
//
//

import Foundation
import UIKit

@objc class Swordfish {
    private static let operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "Swordfish"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private static let logFilePath: String = {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let fileName = documentsDirectory.stringByAppendingPathComponent("swordfish.log")
        return fileName
    }()
    
    private static var logFileHandle: NSFileHandle?
    
    private static var appSessionInfo: [String : AnyObject]?
    
    class func setupAnalyticsWithAppSessionInfo(sessionInfo: [String : AnyObject]?) {
        setAppSessionInfo(sessionInfo)
        
        // Check if log file already exists. If so, attempt to upload it.
        // If not, create the file
        if NSFileManager.defaultManager().fileExistsAtPath(logFilePath) {
            uploadLogFile()
        } else {
            NSFileManager.defaultManager().createFileAtPath(logFilePath, contents: nil, attributes: nil)
            logFileHandle = NSFileHandle(forUpdatingAtPath: logFilePath)
        }
        
        // swizzle methods
        method_exchangeImplementations(
            class_getInstanceMethod(UIViewController.self, "viewDidAppear:"),
            class_getInstanceMethod(UIViewController.self, "Swordfish_viewDidAppear:"))
        method_exchangeImplementations(
            class_getInstanceMethod(UIApplication.self, "sendAction:to:from:forEvent:"),
            class_getInstanceMethod(UIApplication.self, "Swordfish_sendAction:to:from:forEvent:"))
    }
    
    class func setAppSessionInfo(newAppSessionInfo: [String : AnyObject]?) {
        appSessionInfo = newAppSessionInfo
    }
    
    class func log(eventMap: [String : AnyObject], withCategory category: String) {
        operationQueue.addOperationWithBlock { () -> Void in
            var logDict: [String : AnyObject] = [
                "category": category,
                "device": UIDevice.currentDevice().systemName,
                "device_os": UIDevice.currentDevice().systemVersion,
                "timestamp": NSDate.timeIntervalSinceReferenceDate(),
                "eventMap": eventMap
            ]
            
            if self.appSessionInfo != nil {
                logDict["session_info"] = self.appSessionInfo
            }
            
            let jsonDict = NSJSONSerialization.dataWithJSONObject(logDict, options:NSJSONWritingOptions(0), error: nil)
            self.logFileHandle?.writeData(jsonDict!)
            self.logFileHandle?.writeData(("\n" as NSString).dataUsingEncoding(NSUTF8StringEncoding)!)
        }
    }
    
    private class func uploadLogFile() {
        // TODO: Upload instead of delete
        NSFileManager.defaultManager().removeItemAtPath(logFilePath, error: nil)
        println("Swordfish - DELETING LOG FILE")
        
        // Create a new file afterwards
        NSFileManager.defaultManager().createFileAtPath(logFilePath, contents: nil, attributes: nil)
        logFileHandle = NSFileHandle(forUpdatingAtPath: logFilePath)
    }
}
