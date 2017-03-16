//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

internal extension String {

    // TODO: Better solution for dates.
    func toIS8601Date() -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Foundation.Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        if let date = formatter.date(from: self) {
            return date
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            if let date = formatter.date(from: self) {
                return date
            }
        }
        return nil
    }
}

internal func determineDefaultLocale(_ json: Any) -> String {
    if let json = json as? NSDictionary, let space = json.client?.space {
        if let locale = (space.locales.filter { $0.isDefault }).first {
            return locale.code
        }
    }

    return Defaults.locale
}

internal func convertStringsToDates(fields: [String: Any]) -> [String: Any] {
    var fieldsWithDates = [String: Any]()

    for (key, value) in fields {
        if let date = (value as? String)?.toIS8601Date() {
            fieldsWithDates[key] = date
        } else {
            fieldsWithDates[key] = value
        }
    }
    return fieldsWithDates
}

// TODO: Rename this method
internal func parseLocalizedFields(_ json: [String: Any]) throws -> (String, [String:[String:Any]]) {
    let map = Map(mappingType: .fromJSON, JSON: json)
    var fields: [String: Any]!
    fields <- map["fields"]

    var locale: String?
    locale <- map["sys.locale"]

    var localizedFields = [String: [String: Any]]()

    // If there is a locale field, we still want to represent the field internally with a
    // localization mapping.
    if let locale = locale {
        localizedFields[locale] = convertStringsToDates(fields: fields)
    } else {

        // In the case that the fields have been returned with the wildcard format `locale=*`
        // Therefore the structure of fieldsWithDates is [String: [String: Any]]
        fields.forEach { fieldName, localizableFields in
            if let fields = localizableFields as? [String: Any] {
                convertStringsToDates(fields: fields).forEach { locale, value in
                    if localizedFields[locale] == nil {
                        localizedFields[locale] = [String: Any]()
                    }
                    localizedFields[locale]?[fieldName] = value
                }
            }
        }
    }

    return (locale ?? Defaults.locale, localizedFields)
}

// TODO:
//
//extension SyncSpace: StaticMappable {
//
//    public static func objectForMapping(map: Map) -> BaseMappable? {
//        var syncSpace = SyncSpace()
//        syncSpace.mapping(map: map)
//        return syncSpace
//    }
//
//    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
//    public func mapping(map: Map) {
//
//
//
//    }
//
//    /// Decode JSON for a SyncSpace
//    public static func decode(_ json: Any) throws -> SyncSpace {
//        var hasMorePages = true
//        var syncUrl: String? = try? json => "nextPageUrl"
//
//        if syncUrl == nil {
//            hasMorePages = false
//            syncUrl = try json => "nextSyncUrl"
//        }
//
//        let (resources, includes) = try Array<Entry>.parseItems(json: json, shouldResolveIncludes: false)
//        return SyncSpace(
//            hasMorePages: hasMorePages,
//            nextUrl: syncUrl!,
//            items: resources,
//            includes: includes
//        )
//    }
//}
