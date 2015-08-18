//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

public class Entry : Resource {
    public var fields: NSDictionary { return json["fields"] as! NSDictionary }
}
