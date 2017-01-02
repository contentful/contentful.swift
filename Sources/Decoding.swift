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

// Cannot cast directly from [String : Any] => [String:Any]
private func convert(_ fields: [String : Any]) -> [String:Any] {
    var result = [String:Any]()
    fields.forEach { result[$0.0] = $0.1 }
    return result
}

private func determineDefaultLocale(_ json: Any) -> String {
    if let json = json as? NSDictionary, let space = json.client?.space {
        if let locale = (space.locales.filter { $0.isDefault }).first {
            return locale.code
        }
    }

    return DEFAULT_LOCALE
}

private func parseLocalizedFields(_ json: Any) throws -> (String, [String:[String:Any]]) {
    let fields = try json => "fields" as! [String : Any]
    let locale: String? = try? json => "sys" => "locale"

    var localizedFields = [String:[String:Any]]()

    if let locale = locale {
        localizedFields[locale] = convert(fields)
    } else {
        fields.forEach { field, fields in
            (fields as? [String : Any])?.forEach { locale, value in
                if localizedFields[locale] == nil {
                    localizedFields[locale] = [String:Any]()
                }

                localizedFields[locale]?[field] = value
            }
        }
    }

    return (locale ?? DEFAULT_LOCALE, localizedFields)
}

extension UInt: Decodable, DynamicDecodable {
    public static var decoder: (Any) throws -> UInt = { try cast($0) }
}

extension Asset: Decodable {
    /// Decode JSON for an Asset
    public static func decode(_ json: Any) throws -> Asset {
        let (locale, localizedFields) = try parseLocalizedFields(json)

        return try Asset(
            sys: (json => "sys") as! [String : Any],
            localizedFields: localizedFields,
            defaultLocale: determineDefaultLocale(json),

            identifier: json => "sys" => "id",
            type: json => "sys" => "type",
            locale: locale
        )
    }
}

extension Array: Decodable {
    fileprivate static func resolveLink(_ value: Any, _ includes: [String:Resource]) -> Any? {
        if let link = value as? [String : Any],
            let sys = link["sys"] as? [String : Any],
            let identifier = sys["id"] as? String,
            let type = sys["linkType"] as? String,
            let include = includes["\(type)_\(identifier)"] {
                return include
        }

        return nil
    }

    fileprivate static func resolveLinks(_ entry: Entry, _ includes: [String:Resource]) -> Entry {
        var localizedFields = [String:[String:Any]]()

        entry.localizedFields.forEach { locale, entryFields in
            var fields = entryFields

            entryFields.forEach { field in
                if let include = resolveLink(field.1, includes) {
                    fields[field.0] = include
                }

                if let links = field.1 as? [[String : Any]] {
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

    static func parseItems(_ json: Any) throws -> [Resource] {
        var includes = [String:Resource]()
        let jsonIncludes = try? json => "includes" as! [String : Any]

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
    public static func decode(_ json: Any) throws -> Array {

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
    public static func decode(_ json: Any) throws -> ContentfulError {
        return try ContentfulError(
            sys: (json => "sys") as! [String : Any],
            identifier: json => "sys" => "id",
            type: json => "sys" => "type",

            message: json => "message",
            requestId: json => "requestId"
        )
    }
}

extension ContentType: Decodable {
    /// Decode JSON for a Content Type
    public static func decode(_ json: Any) throws -> ContentType {
        return try ContentType(
            sys: (json => "sys") as! [String : Any],
            fields: json => "fields",

            identifier: json => "sys" => "id",
            name: json => "name",
            type: json => "sys" => "type"
        )
    }
}

extension DeletedResource: Decodable {
    /// Decode JSON for a deleted resource
    static func decode(_ json: Any) throws -> DeletedResource {
        return try DeletedResource(
            sys: (json => "sys") as! [String : Any],
            identifier: json => "sys" => "id",
            type: json => "sys" => "type"
        )
    }
}

extension Entry: Decodable {
    /// Decode JSON for an Entry
    public static func decode(_ json: Any) throws -> Entry {
        let (locale, localizedFields) = try parseLocalizedFields(json)

        return try Entry(
            sys: (json => "sys") as! [String : Any],
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
    public static func decode(_ json: Any) throws -> Field {
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
    public static func decode(_ json: Any) throws -> Locale {
        return try Locale(
            code: json => "code",
            isDefault: json => "default",
            name: json => "name"
        )
    }
}

private extension Resource {
    static func decode(_ jsonIncludes: [String : Any], _ includes: inout [String:Resource]) throws {
        let typename = "\(Self.self)"

        if let resources = jsonIncludes[typename] as? [[String : Any]] {
            for resource in resources {
                let value = try self.decode(resource) as Resource
                includes[value.key] = value
            }
        }
    }

    var key: String { return "\(type(of: self))_\(self.identifier)" }
}

extension Space: Decodable {
    /// Decode JSON for a Space
    public static func decode(_ json: Any) throws -> Space {
        return try Space(
            sys: (json => "sys") as! [String : Any],

            identifier: json => "sys" => "id",
            locales: json => "locales",
            name: json => "name",
            type: json => "sys" => "type"
        )
    }
}

extension SyncSpace: Decodable {
    /// Decode JSON for a SyncSpace
    public static func decode(_ json: Any) throws -> SyncSpace {
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
