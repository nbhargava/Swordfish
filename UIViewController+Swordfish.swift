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
        Swordfish.log(["view": NSStringFromClass(self.dynamicType), "animated": animated], withCategory: "view_appeared")
        
        Swordfish_viewDidAppear(animated)
    }
}
