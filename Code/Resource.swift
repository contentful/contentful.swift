//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public class Resource {
    let json : NSDictionary

    public var sys: NSDictionary { return json["sys"] as! NSDictionary }
    public var identifier: String { return self.sys["id"] as! String }
    public var type: String { return self.sys["type"] as! String }

    public required init(data: NSData) {
        json = try! NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! NSDictionary
    }
}
