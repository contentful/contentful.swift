//
//  Field.swift
//  Contentful
//
//  Created by Boris Bügling on 30/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

/// The possible Field types in Contentful
public enum FieldType: String {
    /// An array of links or symbols
    case Array      = "Array"
    /// A link to an Asset
    case Asset      = "Asset"
    /// A boolean value, true or false
    case Boolean    = "Boolean"
    /// A date value with optional time component
    case Date       = "Date"
    /// A link to an Entry
    case Entry      = "Entry"
    /// A numeric integer value
    case Integer    = "Integer"
    /// A link to an Asset or Entry
    case Link       = "Link"
    /// A location value, consists of latitude and longitude
    case Location   = "Location"
    /// An unknown kind of value
    case None
    /// A floating point number value
    case Number     = "Number"
    /// A JSON object value
    case Object     = "Object"
    /// A short text string, can be part of an array
    case Symbol     = "Symbol"
    /// A longer text string
    case Text       = "Text"
}

/// A Field describes a single value inside an Entry
public struct Field {
    /// The unique identifier of this Field
    public let identifier: String
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
    public let itemType: FieldType
}
