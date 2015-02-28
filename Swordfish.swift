//
//  Swordfish.swift
//
//  Created by Nikhil on 2/8/15.
//
//

import Foundation
import UIKit

@objc class Swordfish {
    private static var setupOnceToken: dispatch_once_t = 0
    
    private static let operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "Swordfish-Logging"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private static let failedUploadQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "Swordfish-Log-Reupload"
        return queue
    }()
    
    private static let logFilePath: String = {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let fileName = documentsDirectory.stringByAppendingPathComponent("swordfish.log")
        return fileName
    }()
    private static let pendingFolderPath: String = {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        return documentsDirectory.stringByAppendingPathComponent("pending")
    }()
    private static let failedFolderPath: String = {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        return documentsDirectory.stringByAppendingPathComponent("failed")
    }()
    private static var logFileHandle: NSFileHandle?
    
    private static var appSessionInfo: [String : AnyObject]?
    private static var uploadUrl = "https://httpbin.org/post"
    
    class func setupAnalyticsWithAppSessionInfo(sessionInfo: [String : AnyObject]?, uploadDestination: String) {
        setAppSessionInfo(sessionInfo)
        uploadUrl = uploadDestination
        
        dispatch_once(&setupOnceToken) {
            for folder in [self.pendingFolderPath, self.failedFolderPath] {
                if !NSFileManager.defaultManager().fileExistsAtPath(folder) {
                    NSFileManager.defaultManager().createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: nil, error: nil)
                }
            }
            
            // Check if log file already exists. If so, attempt to upload it.
            // If not, create the file
            if NSFileManager.defaultManager().fileExistsAtPath(self.logFilePath) {
                self.uploadLogFile()
            } else {
                NSFileManager.defaultManager().createFileAtPath(self.logFilePath, contents: nil, attributes: nil)
                self.logFileHandle = NSFileHandle(forUpdatingAtPath: self.logFilePath)
            }
            
            let previouslyFailedLogFiles = NSFileManager.defaultManager().contentsOfDirectoryAtPath(self.failedFolderPath, error: nil)
            for file in previouslyFailedLogFiles! {
                if file.pathExtension == "log" {
                    self.failedUploadQueue.addOperationWithBlock({ () -> Void in
                        self.reuploadLog(self.failedFolderPath.stringByAppendingPathComponent(file as! String))
                    })
                }
            }
            
            // swizzle methods
            method_exchangeImplementations(
                class_getInstanceMethod(UIViewController.self, "viewDidAppear:"),
                class_getInstanceMethod(UIViewController.self, "Swordfish_viewDidAppear:"))
            method_exchangeImplementations(
                class_getInstanceMethod(UIApplication.self, "sendAction:to:from:forEvent:"),
                class_getInstanceMethod(UIApplication.self, "Swordfish_sendAction:to:from:forEvent:"))
            
            let timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("requestUploadLogFile"), userInfo: nil, repeats: true)
        }
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
                "timestamp": self.currentTimeInMS(),
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
    
    class func requestUploadLogFile() {
        operationQueue.addOperationWithBlock { () -> Void in
            self.uploadLogFile()
        }
    }
    
    private class func uploadLogFile() {
        // Temporarily move the existing log file to a different location
        let pendingDestination = pendingFolderPath.stringByAppendingPathComponent("swordfish-\(currentTimeInMS()).log")
        NSFileManager.defaultManager().moveItemAtPath(logFilePath, toPath: pendingDestination, error: nil)
        
        upload(.POST, uploadUrl, NSURL(fileURLWithPath: logFilePath)!).responseJSON { (request, response, JSON, error) in
            if error != nil {
                // Upload failed, so prepare for future upload
                let failedDestination = self.failedFolderPath.stringByAppendingPathComponent("swordfish-\(Int(NSDate.timeIntervalSinceReferenceDate())).log")
                NSFileManager.defaultManager().moveItemAtPath(pendingDestination, toPath: failedDestination, error: nil)
                self.failedUploadQueue.addOperationWithBlock({ () -> Void in
                    self.reuploadLog(failedDestination)
                })
            } else {
                // Safe to delete log file
                NSFileManager.defaultManager().removeItemAtPath(pendingDestination, error: nil)
            }
        }
        
        // Create a new file afterwards
        NSFileManager.defaultManager().createFileAtPath(logFilePath, contents: nil, attributes: nil)
        logFileHandle = NSFileHandle(forUpdatingAtPath: logFilePath)
    }
    
    private class func reuploadLog(filePath: String) {
        upload(.POST, uploadUrl, NSURL(fileURLWithPath: filePath)!).responseJSON { (request, response, JSON, error) in
            if error != nil {
                // Upload failed, so prepare for future upload
                self.failedUploadQueue.addOperationWithBlock({ () -> Void in
                    self.reuploadLog(filePath)
                })
            } else {
                // Safe to delete log file
                NSFileManager.defaultManager().removeItemAtPath(filePath, error: nil)
            }
        }
    }
    
    private class func currentTimeInMS() -> Int {
        return Int(1000 * NSDate.timeIntervalSinceReferenceDate())
    }
}
