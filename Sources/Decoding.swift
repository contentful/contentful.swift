//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation

private let DEFAULT_LOCALE = "en-US"

// Cannot cast directly from [String:AnyObject] => [String:Any]
private func convert(fields: [String:AnyObject]) -> [String:Any] {
    var result = [String:Any]()
    fields.forEach { result[$0.0] = $0.1 }
    return result
}

private func determineDefaultLocale(json: AnyObject) -> String {
    if let json = json as? NSDictionary, space = json.client?.space {
        if let locale = (space.locales.filter { $0.isDefault }).first {
            return locale.code
        }
    }

    return DEFAULT_LOCALE
}

private func parseLocalizedFields(json: AnyObject) throws -> (String, [String:[String:Any]]) {
    let fields = try json => "fields" as! [String:AnyObject]
    let locale: String? = try? json => "sys" => "locale"

    var localizedFields = [String:[String:Any]]()

    if let locale = locale {
        localizedFields[locale] = convert(fields)
    } else {
        fields.forEach { field, fields in
            (fields as? [String:AnyObject])?.forEach { locale, value in
                if localizedFields[locale] == nil {
                    localizedFields[locale] = [String:Any]()
                }

                localizedFields[locale]?[field] = value
            }
        }
    }

    return (locale ?? DEFAULT_LOCALE, localizedFields)
}

extension UInt: Castable {}

extension Asset: Decodable {
    /// Decode JSON for an Asset
    public static func decode(json: AnyObject) throws -> Asset {
        let (locale, localizedFields) = try parseLocalizedFields(json)

        return try Asset(
            sys: (json => "sys") as! [String : AnyObject],
            localizedFields: localizedFields,
            defaultLocale: determineDefaultLocale(json),

            identifier: json => "sys" => "id",
            type: json => "sys" => "type",
            locale: locale
        )
    }
}

extension Array: Decodable {
    private static func resolveLink(value: Any, _ includes: [String:Resource]) -> Any? {
        if let link = value as? [String:AnyObject],
            sys = link["sys"] as? [String:AnyObject],
            identifier = sys["id"] as? String,
            type = sys["linkType"] as? String,
            include = includes["\(type)_\(identifier)"] {
                return include
        }

        return nil
    }

    private static func resolveLinks(entry: Entry, _ includes: [String:Resource]) -> Entry {
        var localizedFields = [String:[String:Any]]()

        entry.localizedFields.forEach { locale, entryFields in
            var fields = entryFields

            entryFields.forEach { field in
                if let include = resolveLink(field.1, includes) {
                    fields[field.0] = include
                }

                if let links = field.1 as? [[String:AnyObject]] {
                    // This drops any unresolvable links automatically
                    let includes = links.map { resolveLink($0, includes) }.flatMap { $0 }
                    if includes.count > 0 {
                        fields[field.0] = includes
                    }
                }
            }

            localizedFields[locale] = fields
        }

        return Entry(entry: entry, localizedFields: localizedFields)
    }

    static func parseItems(json: AnyObject) throws -> [Resource] {
        var includes = [String:Resource]()
        let jsonIncludes = try? json => "includes" as! [String:AnyObject]

        if let jsonIncludes = jsonIncludes {
            try Asset.decode(jsonIncludes, &includes)
            try Entry.decode(jsonIncludes, &includes)
        }

        let items: [Resource] = try (try json => "items" as! [AnyObject]).flatMap {
            let type: String = try $0 => "sys" => "type"

            switch type {
            case "Asset": return try Asset.decode($0)
            case "ContentType": return try ContentType.decode($0)
            case "DeletedAsset": return try DeletedResource.decode($0)
            case "DeletedEntry": return try DeletedResource.decode($0)
            case "Entry": return try Entry.decode($0)
            default: fatalError("Unsupported resource type '\(type)'")
            }
        }

        for item in items {
            includes[item.key] = item
        }

        for (key, resource) in includes {
            if let entry = resource as? Entry {
                includes[key] = resolveLinks(entry, includes)
            }
        }

        return items.map { (item) in
            if let entry = item as? Entry {
                return resolveLinks(entry, includes)
            }
            return item
        }
    }

    /// Decode JSON for an Array
    public static func decode(json: AnyObject) throws -> Array {
        return try Array(
            items: parseItems(json).flatMap { $0 as? T },

            limit: json => "limit",
            skip: json => "skip",
            total: json => "total"
        )
    }
}

extension ContentfulError: Decodable {
    /// Decode JSON for a Contentful error
    public static func decode(json: AnyObject) throws -> ContentfulError {
        return try ContentfulError(
            sys: (json => "sys") as! [String : AnyObject],
            identifier: json => "sys" => "id",
            type: json => "sys" => "type",

            message: json => "message",
            requestId: json => "requestId"
        )
    }
}

extension ContentType: Decodable {
    /// Decode JSON for a Content Type
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

extension DeletedResource: Decodable {
    /// Decode JSON for a deleted resource
    static func decode(json: AnyObject) throws -> DeletedResource {
        return try DeletedResource(
            sys: (json => "sys") as! [String : AnyObject],
            identifier: json => "sys" => "id",
            type: json => "sys" => "type"
        )
    }
}

extension Entry: Decodable {
    /// Decode JSON for an Entry
    public static func decode(json: AnyObject) throws -> Entry {
        let (locale, localizedFields) = try parseLocalizedFields(json)

        return try Entry(
            sys: (json => "sys") as! [String : AnyObject],
            localizedFields: localizedFields,
            defaultLocale: determineDefaultLocale(json),

            identifier: json => "sys" => "id",
            type: json => "sys" => "type",
            locale: locale
        )
    }
}

extension Field: Decodable {
    /// Decode JSON for a Field
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
    /// Decode JSON for a Locale
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
                let value = try self.decode(resource) as Resource
                includes[value.key] = value
            }
        }
    }

    var key: String { return "\(self.dynamicType)_\(self.identifier)" }
}

extension Space: Decodable {
    /// Decode JSON for a Space
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

extension SyncSpace: Decodable {
    /// Decode JSON for a SyncSpace
    public static func decode(json: AnyObject) throws -> SyncSpace {
        var nextPage = true
        var syncUrl: String? = try? json => "nextPageUrl"

        if syncUrl == nil {
            nextPage = false
            syncUrl = try json => "nextSyncUrl"
        }

        return SyncSpace(
            nextPage: nextPage,
            nextUrl: syncUrl!,
            items: try Array<Entry>.parseItems(json)
        )
    }
}
