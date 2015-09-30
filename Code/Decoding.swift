//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable

extension UInt: Castable {}

extension Asset: Decodable {
    public static func decode(json: AnyObject) throws -> Asset {
        let urlString: String = try json => "fields" => "file" => "url"
        // FIXME: Scheme should not be hardcoded
        guard let url = NSURL(string: "https:\(urlString)") else {
            throw ContentfulError.InvalidURL(string: urlString)
        }

        return try Asset(
            sys: json => "sys",
            fields: json => "fields",

            identifier: json => "sys" => "id",
            type: json => "sys" => "type",
            URL: url
        )
    }
}

extension ContentfulArray: Decodable {
    public static func decode(json: AnyObject) throws -> ContentfulArray {
        return try ContentfulArray(
            items: json => "items",

            limit: json => "limit",
            skip: json => "skip",
            total: json => "total"
        )
    }
}

extension ContentType: Decodable {
    public static func decode(json: AnyObject) throws -> ContentType {
        return try ContentType(
            sys: json => "sys",
            fields: json => "fields",

            identifier: json => "sys" => "id",
            type: json => "sys" => "type"
        )
    }
}

extension Entry: Decodable {
    public static func decode(json: AnyObject) throws -> Entry {
        return try Entry(
            sys: json => "sys",
            fields: json => "fields",

            identifier: json => "sys" => "id",
            type: json => "sys" => "type"
        )
    }
}

extension Field: Decodable {
    public static func decode(json: AnyObject) throws -> Field {
        return try Field(
            identifier: json => "id",
            name: json => "name"
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

extension Space: Decodable {
    public static func decode(json: AnyObject) throws -> Space {
        return try Space(
            sys: json => "sys",

            identifier: json => "sys" => "id",
            locales: json => "locales",
            name: json => "name",
            type: json => "sys" => "type"
        )
    }
}
