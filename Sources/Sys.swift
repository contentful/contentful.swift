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

    /// Resource type
    public let type: String

    /// Read-only property describing the date the `Resource` was created.
    public let createdAt: Date?

    /// Read-only property describing the date the `Resource` was last updated.
    public let updatedAt: Date?

    /// Currently selected locale
    public var locale: String?

    /// The identifier for the ContentType. 
    public let contentTypeId: String?

    public let revision: Int?

    // MARK: <ImmutableMappable>

    public init(map: Map) throws {
        // Properties present in all sys structures.
        id              = try map.value("id")
        type            = try map.value("type")

        // Optional properties.
        locale          = try? map.value("locale")
        contentTypeId   = try? map.value("contentType.sys.id")
        revision        = try? map.value("revision")

        // Dates
        let iso8601DateTransform = SysISO8601DateTransform()
        createdAt       = try? map.value("createdAt", using: iso8601DateTransform)
        updatedAt       = try? map.value("updatedAt", using: iso8601DateTransform)
    }
}
