//
//  ContentType.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// A Content Type represents your data model for Entries in a Contentful Space
public class ContentType: Resource, Decodable {

    ///  System fields.
    public let sys: Sys

    /// The fields which are part of this Content Type
    public let fields: [Field]

    /// The name of this Content Type
    public let name: String

    /// Resource type ("ContentType")
    public var type: String {
        return sys.type
    }

    public required init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        sys             = try container.decode(Sys.self, forKey: .sys)
        fields          = try container.decode([Field].self, forKey: .fields)
        name            = try container.decode(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case sys, fields, name
    }
}
