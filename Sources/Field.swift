//
//  Field.swift
//  Contentful
//
//  Created by Boris Bügling on 30/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import ObjectMapper

public typealias FieldName = String

/// The possible Field types in Contentful
public enum FieldType: String {
    /// An array of links or symbols
    case array                          = "Array"
    /// A link to an Asset
    case asset                          = "Asset"
    /// A boolean value, true or false
    case boolean                        = "Boolean"
    /// A date value with optional time component
    case date                           = "Date"
    /// A link to an Entry
    case entry                          = "Entry"
    /// A numeric integer value
    case integer                        = "Integer"
    /// A link to an Asset or Entry
    case link                           = "Link"
    /// A location value, consists of latitude and longitude
    case location                       = "Location"
    /// A floating point number value
    case number                         = "Number"
    /// A JSON object value
    case object                         = "Object"
    /// A short text string, can be part of an array
    case symbol                         = "Symbol"
    /// A longer text string
    case text                           = "Text"
    /// An unknown kind of value
    case none                           = "None"
}

/// A Field describes a single value inside an Entry
// Hitting the /content_types endpoint will return a JSON field "fields" that
// maps to an array where each element has the following structure.
public struct Field: ImmutableMappable {
    /// The unique identifier of this Field
    public let id: String
    /// The name of this Field
    public let name: String

    /// Whether this field is disabled (invisible by default in the UI)
    public let disabled: Bool
    /// Whether this field is localized (can have different values depending on locale)
    public let localized: Bool
    /// Whether this field is required (needs to have a value)
    public let required: Bool

    /// The type of this Field
    public let type: FieldType

    /// The item type of this Field (a subtype if `type` is `Array` or `Link`)
    // For `Array`s, itemType is inferred via items.type. 
    // For `Link`s, itemType is inferred via "linkType"
    public let itemType: FieldType?

    // MARK: <ImmutableMappable>

    public init(map: Map) throws {
        id          = try map.value("id")
        name        = try map.value("name")
        disabled    = try map.value("disabled")
        localized   = try map.value("localized")
        required    = try map.value("required")

        var typeString: String!
        typeString <- map["type"]
        type = FieldType(rawValue: typeString) ?? .none

        var itemTypeString: String?

        itemTypeString <- map["items.type"]
        itemTypeString <- map["items.linkType"]
        itemTypeString <- map["linkType"]

        self.itemType = FieldType(rawValue: itemTypeString ?? FieldType.none.rawValue) ?? .none
    }
}
