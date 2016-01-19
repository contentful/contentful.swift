//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// An Entry represents a typed collection of data in Contentful
public struct Entry : Resource {
    /// System fields
    public let sys: [String:AnyObject]
    /// Content fields
    public let fields: [String:Any]

    /// The unique identifier of this Entry
    public let identifier: String
    /// Resource type ("Entry")
    public let type: String
}
