//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public struct Entry : Resource {
    public let sys: [String:AnyObject]
    public let fields: [String:AnyObject]

    public let identifier: String
    public let type: String
}
