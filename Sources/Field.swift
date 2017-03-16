//
//  Field.swift
//  Contentful
//
//  Created by Boris Bügling on 30/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import ObjectMapper

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
public struct Field: StaticMappable {
    /// The unique identifier of this Field
    public var id: String!
    /// The name of this Field
    public var name: String!

    /// Whether this field is disabled (invisible by default in the UI)
    public var disabled: Bool!
    /// Whether this field is localized (can have different values depending on locale)
    public var localized: Bool!
    /// Whether this field is required (needs to have a value)
    public var required: Bool!

    /// The type of this Field
    public var type: FieldType!

    /// The item type of this Field (a subtype if `type` is `Array` or `Link`)
    // For `Array`s, itemType is inferred via items.type. 
    // For `Link`s, itemType is inferred via "linkType"
    public var itemType: FieldType!

    // MARK: - StaticMappable

    public static func objectForMapping(map: Map) -> BaseMappable? {
        var field = Field()
        field.mapping(map: map)
        return field
    }

    public mutating func mapping(map: Map) {
        id          <- map["id"]
        name        <- map["name"]
        disabled    <- map["disabled"]
        localized   <- map["localized"]
        required    <- map["required"]

        // TODO: Improve this code
        var type: String!
        type <- map["type"]
        self.type = FieldType(rawValue: type) ?? .none

        if self.type == .array {
            var itemType: String!
            itemType <- map["items.type"]
            if itemType == "Link" {
                itemType <- map["items.linkType"]
            }
            self.itemType = FieldType(rawValue: itemType) ?? .none
        } else if self.type == .link {
            var itemType: String!
            itemType <- map["linkType"]
            self.itemType = FieldType(rawValue: itemType) ?? .none
        }
    }



    //    /// Decode JSON for a Field
    //    public static func decode(_ json: Any) throws -> Field {
    //        var itemType: FieldType = .none
    //        if let itemTypeString = (try? json => "items" => "type") as? String {
    //            itemType = FieldType(rawValue: itemTypeString) ?? .none
    //        }
    //        if let itemTypeString = (try? json => "items" => "linkType") as? String {
    //            itemType = FieldType(rawValue: itemTypeString) ?? .none
    //        }
    //        if let linkTypeString = (try? json => "linkType") as? String {
    //            itemType = FieldType(rawValue: linkTypeString) ?? .none
    //        }
    //
    //        return try Field(
    //            identifier: json => "id",
    //            name: json => "name",
    //
    //            disabled: (try? json => "disabled") ?? false,
    //            localized: (try? json => "localized") ?? false,
    //            required: (try? json => "required") ?? false,
    //
    //            type: FieldType(rawValue: try json => "type") ?? .none,
    //            itemType: itemType
    //        )
    //    }
}
