//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// A Space represents a collection of content types, locales, assets, and entries in Contentful.
public class Space: Resource, FlatResource, Decodable {

    /// System fields.
    public let sys: Sys

    /// Available locales for this Space
    public let locales: [Locale]

    /// The name of this Space.
    public let name: String

    /// Resource type ("Space").
    public var type: String {
        return sys.type
    }

    // MARK: <Decodable>

    public required init(from decoder: Decoder) throws {
        let container       = try decoder.container(keyedBy: CodingKeys.self)
        sys                 = try container.decode(Sys.self, forKey: .sys)
        name                = try container.decode(String.self, forKey: .name)
        locales             = try container.decode([Locale].self, forKey: .locales)
    }

    private enum CodingKeys: String, CodingKey {
        case sys
        case name
        case locales
    }
}

extension Space: EndpointAccessible {

    public static let endpoint = Endpoint.spaces
}
