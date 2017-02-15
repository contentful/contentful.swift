//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation

// Cannot cast directly from [String : Any] => [String:Any]
private func convert(_ fields: [String : Any]) -> [String:Any] {
    var result = [String: Any]()
    fields.forEach { result[$0.0] = $0.1 }
    return result
}

private func determineDefaultLocale(_ json: Any) -> String {
    if let json = json as? NSDictionary, let space = json.client?.space {
        if let locale = (space.locales.filter { $0.isDefault }).first {
            return locale.code
        }
    }

    return Defaults.locale
}

private func parseLocalizedFields(_ json: Any) throws -> (String, [String:[String:Any]]) {
    let fields = try json => "fields" as! [String : Any]
    let locale: String? = try? json => "sys" => "locale"

    var localizedFields = [String: [String: Any]]()

    if let locale = locale {
        localizedFields[locale] = convert(fields)
    } else {
        fields.forEach { field, fields in
            (fields as? [String : Any])?.forEach { locale, value in
                if localizedFields[locale] == nil {
                    localizedFields[locale] = [String: Any]()
                }

                localizedFields[locale]?[field] = value
            }
        }
    }

    return (locale ?? Defaults.locale, localizedFields)
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

    internal static func parseItems(json: Any, shouldResolveIncludes: Bool = true) throws -> (resources: [Resource], includes: [String: Resource]) {

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

        // Resolve links.
        var includes = [String: Resource]()
        let jsonIncludes = try? json => "includes" as! [String:Any]

        if let jsonIncludes = jsonIncludes {
            try Asset.decode(jsonIncludes, &includes)
            try Entry.decode(jsonIncludes, &includes)
        }

        for item in items {
            // item.key is it's typename concatenated with it's identifier.
            includes[item.key] = item
        }

        guard shouldResolveIncludes == true else {
            return (resources: items, includes: includes)
        }

        // Complete the relationship graph within the includes dictionary itself.
        for (key, resource) in includes {
            if let entry = resource as? Entry {
                includes[key] = entry.resolveLinks(againstIncludes: includes)
            }
        }

        // Then update the returned resources themselves by resolving the includes...
        let resources: [Resource] =  items.map { item in
            if let entry = item as? Entry {
                return entry.resolveLinks(againstIncludes: includes)
            }
            return item
        }

        return (resources: resources, includes: includes)
    }

    /// Decode JSON for an Array
    public static func decode(_ json: Any) throws -> Array {

        return try Array(
            items: parseItems(json: json).resources.flatMap { $0 as? T },
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
        var hasMorePages = true
        var syncUrl: String? = try? json => "nextPageUrl"

        if syncUrl == nil {
            hasMorePages = false
            syncUrl = try json => "nextSyncUrl"
        }

        let (resources, includes) = try Array<Entry>.parseItems(json: json, shouldResolveIncludes: false)
        return SyncSpace(
            hasMorePages: hasMorePages,
            nextUrl: syncUrl!,
            items: resources,
            includes: includes
        )
    }
}
