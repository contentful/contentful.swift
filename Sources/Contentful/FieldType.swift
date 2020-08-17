//
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

/// The possible Field types in a Contentful content type.
public enum FieldType: String, Decodable {
    /// An array of links or symbols
    case array = "Array"

    /// A link to an Asset
    case asset = "Asset"

    /// A boolean value, true or false
    case boolean = "Boolean"

    /// A date value with optional time component
    case date = "Date"

    /// A link to an Entry
    case entry = "Entry"

    /// A numeric integer value
    case integer = "Integer"

    /// A link to an Asset or Entry
    case link = "Link"

    /// A location value, consists of latitude and longitude
    case location = "Location"

    /// A floating point number value
    case number = "Number"

    /// A JSON object value
    case object = "Object"

    /// A short text string, can be part of an array
    case symbol = "Symbol"

    /// A longer text string
    case text = "Text"

    /// An unknown kind of value
    case none = "None"

    /// The rich text field type.
    case richText = "RichText"
}
