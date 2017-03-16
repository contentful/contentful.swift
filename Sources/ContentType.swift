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
    public var fields: [Field]!

//    /// The unique identifier of this Content Type
//    public let identifier: String
    /// The name of this Content Type
    public var name: String!
//    /// Resource type ("ContentType")
//    public let type: String


    public override class func objectForMapping(map: ObjectMapper.Map) -> BaseMappable? {
        let contentType = ContentType()
        contentType.mapping(map: map)
        return contentType
    }

    public override func mapping(map: Map) {
        super.mapping(map: map)
        fields  <- map["fields"]
        name    <- map["name"]
    }
}
