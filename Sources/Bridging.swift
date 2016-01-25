//
//  Bridging.swift
//  Contentful
//
//  Created by Boris Bügling on 26/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

/*
 This is needed with Swift 2.2 snapshots as of 2016/01/26, probably can go away in the future.
 */

import Foundation

#if os(Linux)
func bridge(any: Any) -> AnyObject {
    if let any = any as? [String:Any] { return bridge(any) }

    if let any = any as? [Any] {
        let array = NSMutableArray()
        any.forEach { array.addObject(bridge($0)) }
        return array
    }

    if let any = any as? String { return NSString(string: any) }
    if let any = any as? Bool { return NSNumber(bool: any) }
    if let any = any as? Double { return NSNumber(double: any) }

    fatalError("Could not bridge \(any.dynamicType)")
}

func bridge(dict: [String:Any]) -> NSDictionary {
    let result = NSMutableDictionary()
    for (key, obj) in dict {
        if let obj = obj as? AnyObject {
            result.setObject(obj, forKey: NSString(string: key))
        } else {
            result.setObject(bridge(obj), forKey: NSString(string: key))
        }
    }
    return result
}

func bridge(array: [NSObject:AnyObject]) -> [String:AnyObject] {
    var result = [String:AnyObject]()
    for (key, value) in array {
        result[key.description] = value
    }
    return result
}
#endif
