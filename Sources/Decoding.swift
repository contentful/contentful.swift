//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation

extension UInt: Castable {}

extension Asset: Decodable {
    public static func decode(json: AnyObject) throws -> Asset {
        let urlString: String = try json => "fields" => "file" => "url"
        // FIXME: Scheme should not be hardcoded
        guard let url = NSURL(string: "https:\(urlString)") else {
            throw ContentfulError.InvalidURL(string: urlString)
        }

        return try Asset(
            sys: (json => "sys") as! [String : AnyObject],
            fields: (json => "fields") as! [String : AnyObject],

            identifier: json => "sys" => "id",
            type: json => "sys" => "type",
            URL: url
        )
    }
}

extension ContentfulArray: Decodable {
    private static func resolveLinks(entry: Entry, _ includes: [String:Resource]) -> Entry {
        var fields = entry.fields

        for field in entry.fields {
            if let link = field.1 as? [String:AnyObject],
                sys = link["sys"] as? [String:AnyObject],
                identifier = sys["id"] as? String,
                type = sys["linkType"] as? String,
                include = includes["\(type)_\(identifier)"] {
                    fields[field.0] = include
            }
        }

        return Entry(sys: entry.sys, fields: fields, identifier:  entry.identifier, type: entry.type)
    }

    public static func decode(json: AnyObject) throws -> ContentfulArray {
        var includes = [String:Resource]()
        let jsonIncludes = try? json => "includes" as! [String:AnyObject]

        if let jsonIncludes = jsonIncludes {
            try Asset.decode(jsonIncludes, &includes)
            try Entry.decode(jsonIncludes, &includes)
        }

        var items: [T] = try json => "items"

        for item in items {
            if let resource = item as? Resource {
                includes[resource.key] = resource
            }
        }

        items = items.map { (item) in
            if let entry = item as? Entry {
                return resolveLinks(entry, includes) as! T
            }
            return item
        }

        return try ContentfulArray(
            items: items,

            limit: json => "limit",
            skip: json => "skip",
            total: json => "total"
        )
    }
}

extension ContentType: Decodable {
    public static func decode(json: AnyObject) throws -> ContentType {
        return try ContentType(
            sys: (json => "sys") as! [String : AnyObject],
            fields: json => "fields",

            identifier: json => "sys" => "id",
            name: json => "name",
            type: json => "sys" => "type"
        )
    }
}

extension Entry: Decodable {
    public static func decode(json: AnyObject) throws -> Entry {
        // Cannot cast directly from [String:AnyObject] => [String:Any]
        var fields = [String:Any]()
        for field in (try json => "fields" as! [String:AnyObject]) {
            fields[field.0] = field.1
        }

        return try Entry(
            sys: (json => "sys") as! [String : AnyObject],
            fields: fields,

            identifier: json => "sys" => "id",
            type: json => "sys" => "type"
        )
    }
}

extension Field: Decodable {
    public static func decode(json: AnyObject) throws -> Field {
        var itemType: FieldType = .None
        if let itemTypeString = (try? json => "items" => "type") as? String {
            itemType = FieldType(rawValue: itemTypeString) ?? .None
        }
        if let itemTypeString = (try? json => "items" => "linkType") as? String {
            itemType = FieldType(rawValue: itemTypeString) ?? .None
        }
        if let linkTypeString = (try? json => "linkType") as? String {
            itemType = FieldType(rawValue: linkTypeString) ?? .None
        }

        return try Field(
            identifier: json => "id",
            name: json => "name",

            disabled: (try? json => "disabled") ?? false,
            localized: (try? json => "localized") ?? false,
            required: (try? json => "required") ?? false,

            type: FieldType(rawValue: try json => "type") ?? .None,
            itemType: itemType
        )
    }
}

extension Locale: Decodable {
    public static func decode(json: AnyObject) throws -> Locale {
        return try Locale(
            code: json => "code",
            isDefault: json => "default",
            name: json => "name"
        )
    }
}

private extension Resource {
    static func decode(jsonIncludes: [String:AnyObject], inout _ includes: [String:Resource]) throws {
        let typename = "\(Self.self)"

        if let resources = jsonIncludes[typename] as? [[String:AnyObject]] {
            for resource in resources {
                #if os(Linux)
                let castedResource = resource as! AnyObject
                #else
                let castedResource = resource as AnyObject
                #endif
                let value = try self.decode(castedResource) as Resource
                includes[value.key] = value
            }
        }
    }

    var key: String { return "\(self.dynamicType)_\(self.identifier)" }
}

extension Space: Decodable {
    public static func decode(json: AnyObject) throws -> Space {
        return try Space(
            sys: (json => "sys") as! [String : AnyObject],

            identifier: json => "sys" => "id",
            locales: json => "locales",
            name: json => "name",
            type: json => "sys" => "type"
        )
    }
}
