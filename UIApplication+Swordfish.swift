//
//  UIApplication+Swordfish.swift
//  
//
//  Created by Nikhil on 2/15/15.
//
//

import UIKit

extension UIApplication {
    func Swordfish_sendAction(action: Selector, to: AnyObject?, from: AnyObject?, forEvent: UIEvent?) -> Bool {
        var eventMap: [String: AnyObject] = [
            "selector": NSStringFromSelector(action),
            "to_object": NSStringFromClass(to?.dynamicType),
            "from_object": NSStringFromClass(from?.dynamicType)
        ]
        if forEvent != nil {
            var subDict: [String: AnyObject] = [
                "name": NSStringFromClass(forEvent!.dynamicType),
                "type": forEvent!.type.rawValue
            ]
            if forEvent!.subtype != .None {
                subDict["subtype"] = forEvent!.subtype.rawValue
            }
            
            eventMap["UIEvent"] = subDict
        }
        
        Swordfish.log(eventMap, withCategory: "send_action")
        
        return Swordfish_sendAction(action, to: to, from: from, forEvent: forEvent)
    }
}
