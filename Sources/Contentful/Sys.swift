//
//  Sys.swift
//  Contentful
//
//  Created by JP Wright on 16/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/// The system fields available on all resources in Contentful. At minimum,
/// all resources have an `id` and a `type` available. Entries and assets provide more information than
public struct Sys {

    /// The unique identifier of the resource..
    public let id: String

    /// The type identifier of the resource.
    public let type: String

    /// Describes the date the resource was created.
    public let createdAt: Date?

    /// Describes the date the resource was last updated.
    public let updatedAt: Date?

    /// The code for the currently selected locale.
    public var locale: LocaleCode? // Not present when hitting /sync or using "*" wildcard locale in request.

    /// The identifier for the content type, if the resource is an `Entry`.
    public var contentTypeId: String? {
        return contentTypeInfo?.sys.id
    }

    /// The number denoting what the published version of the resource is.
    public let revision: Int?

    /// The link describing the resource type. Not present on `Asset` or `ContentType` resources.
    public let contentTypeInfo: Link?
}

extension Sys: Decodable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id              = try container.decode(String.self, forKey: .id)
        type            = try container.decode(String.self, forKey: .type)
        createdAt       = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt       = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        locale          = try container.decodeIfPresent(String.self, forKey: .locale)
        revision        = try container.decodeIfPresent(Int.self, forKey: .revision)
        contentTypeInfo = try container.decodeIfPresent(Link.self, forKey: .contentType)
    }

    /// The JSON keys for a `Sys` instance.
    public enum CodingKeys: String, CodingKey {
        /// The JSON keys for a Sys object.
        case id, type, createdAt, updatedAt, locale, revision, contentType
    }
}
