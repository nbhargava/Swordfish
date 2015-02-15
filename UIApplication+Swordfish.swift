//
//  UIApplication+Swordfish.swift
//  
//
//  Created by Nikhil on 2/15/15.
//
//

import UIKit

extension UIApplication {
    func Swordfish_sendAction(action : Selector, to: AnyObject?, from: AnyObject?, forEvent: UIEvent?) -> Bool {
        println("Swordfish action sent")
        println("   Selector    = {\(NSStringFromSelector(action))}")
        println("   to          = {\(NSStringFromClass(to?.dynamicType))}")
        println("   from        = {\(NSStringFromClass(from?.dynamicType))}")
        if (forEvent != nil) {
            println("   event       = {\(NSStringFromClass(forEvent!.dynamicType))}")
            println("   event.type  = {\(forEvent!.type.rawValue)}")
            if (forEvent?.subtype != .None) {
                println("   event.subtype = {\(forEvent!.subtype.rawValue)}")
            }
        }
        
        return Swordfish_sendAction(action, to: to, from: from, forEvent: forEvent)
    }
}
