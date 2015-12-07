//
//  Field.swift
//  Contentful
//
//  Created by Boris Bügling on 30/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

public enum FieldType: String {
    case Array      = "Array"
    case Asset      = "Asset"
    case Boolean    = "Boolean"
    case Date       = "Date"
    case Entry      = "Entry"
    case Integer    = "Integer"
    case Link       = "Link"
    case Location   = "Location"
    case None
    case Number     = "Number"
    case Object     = "Object"
    case Symbol     = "Symbol"
    case Text       = "Text"
}

public struct Field {
    public let identifier: String
    public let name: String

    public let disabled: Bool
    public let localized: Bool
    public let required: Bool

    public let type: FieldType
    public let itemType: FieldType
}
