//
//  ContentType.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/// A Content Type represents your data model for Entries in a Contentful Space
public class ContentType: Resource {

    /// The fields which are part of this Content Type
    public let fields: [Field]

    /// The name of this Content Type
    public let name: String

    /// Resource type ("ContentType")
    public var type: String {
        return sys.type
    }


    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {
        fields  = try map.value("fields")
        name    = try map.value("name")

        try super.init(map: map)
    }
}
