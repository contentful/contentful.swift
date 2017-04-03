//
//  Sys.swift
//  Contentful
//
//  Created by JP Wright on 16/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

public struct Sys: ImmutableMappable {

    /// The unique id.
    public let id: String

    /// Read-only property describing the date the `Resource` was created.
    public let createdAt: String?

    /// Read-only property describing the date the `Resource` was last updated.
    public let updatedAt: String?

    /// Currently selected locale
    public var locale: String?

    /// Resource type
    public let type: String

    /// The identifier for the ContentType. 
    public let contentTypeId: String?

    public let revision: Int?

    // MARK: <ImmutableMappable>

    public init(map: Map) throws {
        id              = try map.value("id")
        type            = try map.value("type")

        locale          = try? map.value("locale")
        contentTypeId   = try? map.value("contentType.sys.id")
        createdAt       = try? map.value("createdAt")
        updatedAt       = try? map.value("updatedAt")
        revision        = try? map.value("revision")
    }
}
