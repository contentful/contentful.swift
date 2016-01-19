//
//  ContentType.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// A Content Type represents your data model for Entries in a Contentful Space
public struct ContentType : Resource {
    /// System fields
    public let sys: [String:AnyObject]
    /// The fields which are part of this Content Type
    public let fields: [Field]

    /// The unique identifier of this Content Type
    public let identifier: String
    /// The name of this Content Type
    public let name: String
    /// Resource type ("ContentType")
    public let type: String
}
