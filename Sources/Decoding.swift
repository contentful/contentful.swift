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

    internal static func parseItems(json: AnyObject, shouldResolveIncludes: Bool = true) throws -> (resources: [Resource], includes: [String:Resource]) {

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
        var includes = [String:Resource]()
        let jsonIncludes = try? json => "includes" as! [String:AnyObject]

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
    public static func decode(json: AnyObject) throws -> Array {

        return try Array(
            items: try parseItems(json).resources.flatMap { $0 as? T },
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
        var hasMorePages = true
        var syncUrl: String? = try? json => "nextPageUrl"

        if syncUrl == nil {
            hasMorePages = false
            syncUrl = try json => "nextSyncUrl"
        }

        let (resources, includes) = try Array<Entry>.parseItems(json, shouldResolveIncludes: false)
        return SyncSpace(
            hasMorePages: hasMorePages,
            nextUrl: syncUrl!,
            items: resources,
            includes: includes
        )
    }
}
