//
//  Sys.swift
//  Contentful
//
//  Created by JP Wright on 16/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

public struct Sys: StaticMappable {

    /// The unique identifier.
    public var id: String!

    // TODO: Document
    public var createdAt: String!

    // TODO: Document
    public var updatedAt: String!

    /// Currently selected locale
    public var locale: String!

    /// Resource type
    public var type: String!

    public var contentTypeId: String?

    // MARK: - StaticMappable

    public static func objectForMapping(map: Map) -> BaseMappable? {
        var sys = Sys()
        sys.mapping(map: map)
        return sys
    }

    mutating public func mapping(map: ObjectMapper.Map) {
        id              <- map["id"]
        createdAt       <- map["createdAt"]
        updatedAt       <- map["updatedAt"]
        locale          <- map["locale"]
        type            <- map["type"]
        contentTypeId   <- map["contentType.sys.id"]
    }
}
