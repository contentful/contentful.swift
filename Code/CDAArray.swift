//
//  CDAArray.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public struct CDAArray<T : Resource> {
    let errors: [ErrorType]? = nil

    let items: [T]

    let limit: UInt
    let skip: UInt
    let total: UInt

    init(data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary

        limit = json["limit"] as! UInt
        skip = json["skip"] as! UInt
        total = json["total"] as! UInt

        var items = [T]()
        for item in (json["items"] as! [NSDictionary]) {
            let data = try! NSJSONSerialization.dataWithJSONObject(item, options: [])
            items.append(T(data: data))
        }
        self.items = items
    }
}
