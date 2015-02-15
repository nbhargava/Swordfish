//
//  Swordfish.swift
//
//  Created by Nikhil on 2/8/15.
//
//

import Foundation
import UIKit

@objc class Swordfish {
    class func setupAnalytics() {
        method_exchangeImplementations(
            class_getInstanceMethod(UIViewController.self, "viewDidLoad"),
            class_getInstanceMethod(UIViewController.self, "Swordfish_viewDidLoad"))
        method_exchangeImplementations(
            class_getInstanceMethod(UIApplication.self, "sendAction:to:from:forEvent:"),
            class_getInstanceMethod(UIApplication.self, "Swordfish_sendAction:to:from:forEvent:"))
    }
}
