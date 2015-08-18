//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

public class Space : Resource {
    public var name: String { return self.json["name"] as! String }
}
