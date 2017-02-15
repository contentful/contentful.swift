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
    case Array
    /// A link to an Asset
    case Asset
    /// A boolean value, true or false
    case Boolean
    /// A date value with optional time component
    case Date
    /// A link to an Entry
    case Entry
    /// A numeric integer value
    case Integer
    /// A link to an Asset or Entry
    case Link
    /// A location value, consists of latitude and longitude
    case Location
    /// An unknown kind of value
    case None
    /// A floating point number value
    case Number
    /// A JSON object value
    case Object
    /// A short text string, can be part of an array
    case Symbol
    /// A longer text string
    case Text
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
