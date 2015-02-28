//
//  UIViewController+Swordfish.swift
//  
//
//  Created by Nikhil on 2/15/15.
//
//

import UIKit

extension UIViewController {
    func Swordfish_viewDidAppear(animated: Bool) {
        var logData: [String : AnyObject] = [
            "view_controller": NSStringFromClass(self.dynamicType),
            "animated": animated,
        ]
        
        Swordfish.log(logData, withCategory: "view_appeared")
        
        Swordfish_viewDidAppear(animated)
    }
}
