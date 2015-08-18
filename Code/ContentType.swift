//
//  ContentType.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public class ContentType : Resource {
    public var fields: [NSDictionary] { return self.json["fields"] as! [NSDictionary] }
}
