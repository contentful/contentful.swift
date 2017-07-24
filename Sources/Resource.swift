//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper
import CoreLocation

/// Protocol for resources inside Contentful
public class Resource: ImmutableMappable {

    /// System fields
    public let sys: Sys

    /// The unique identifier of this Resource
    public var id: String {
        return sys.id
    }

    internal init(sys: Sys) {
        self.sys = sys
    }

    // MARK: - <ImmutableMappable>

    public required init(map: Map) throws {
        sys = try map.value("sys")
    }
}

class DeletedResource: Resource {}

/**
 LocalizableResource
 
 Base class for any Resource that has the capability of carrying information for multiple locales.
 If more than one locale is fetched using either `/sync` endpoint, or specifying the wildcard value
 for the locale paramater (i.e ["locale": "*"]) during a fetch, the SDK will cache returned values for 
 all locales. This class gives an interface to specify which locale should be used when fetching data
 from `Resource` instances that are in memory.
 */
public class LocalizableResource: Resource {

    /// Currently selected locale to use when reading data from the `fields` dictionary.
    public var currentlySelectedLocale: Locale

    /**
     Content fields. If there is no value for a field associated with the currently selected `Locale`,
     the SDK will walk down fallback chain until a value is found. If there is still no value after
     walking the full chain, the field will be omitted from the `fields` dictionary.
    */
    public var fields: [FieldName: Any] {
        return Localization.fields(forLocale: currentlySelectedLocale, localizableFields: localizableFields, localizationContext: localizationContext)
    }

    /** Set's the locale on the Localizable Resource (i.e. an instance of `Asset` or `Entry`) 
        so that future reads from the `fields` property will return data corresponding 
        to the specified locale code.
     */
    @discardableResult public func setLocale(withCode code: LocaleCode) -> Bool {
        guard let newLocale = localizationContext.locales[code] else {
            return false
        }
        currentlySelectedLocale = newLocale
        return true
    }

    // Locale to Field mapping.
    internal var localizableFields: [FieldName: [LocaleCode: Any]]

    // Context used for handling locales during decoding of `Asset` and `Entry` instances.
    internal let localizationContext: LocalizationContext


    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {

        // Optional propery, not returned when hitting `/sync`.
        var localeCodeSelectedAtAPILevel: LocaleCode?
        localeCodeSelectedAtAPILevel <- map["sys.locale"]

        guard let localizationContext = map.context as? LocalizationContext else {
            // Should never get here; but just in case, let's inform the user what the deal is.
            throw SDKError.localeHandlingError(message: "SDK failed to find the necessary LocalizationContext"
            + "necessary to properly map API responses to internal format.")
        }

        self.localizationContext = localizationContext

        // Get currently selected locale.
        if let localeCode = localeCodeSelectedAtAPILevel, let locale = localizationContext.locales[localeCode] {
            self.currentlySelectedLocale = locale
        } else {
            self.currentlySelectedLocale = localizationContext.default
        }

        self.localizableFields = try Localization.fieldsInMultiLocaleFormat(from: map, selectedLocale: currentlySelectedLocale)

        try super.init(map: map)
    }
}

extension Resource: Hashable {
    public var hashValue: Int {
        return id.hashValue
    }
}

extension Resource: Equatable {}
public func == (lhs: Resource, rhs: Resource) -> Bool {
    return lhs.id == rhs.id && lhs.sys.updatedAt == rhs.sys.updatedAt
}


func +=<K: Hashable, V> (left: [K: V], right: [K: V]) -> [K: V] {
    var result = left
    right.forEach { (key, value) in result[key] = value }
    return result
}

func +<K: Hashable, V> (left: [K: V], right: [K: V]) -> [K: V] {
    return left += right
}

public extension Dictionary where Key: ExpressibleByStringLiteral {

    func string(at key: Key) -> String? {
        return self[key] as? String
    }

    func strings(at key: Key) -> [String]? {
        return self[key] as? [String]
    }

    func int(at key: Key) -> Int? {
        return self[key] as? Int
    }
}
