//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Protocol for resources inside Contentful
public protocol Resource {

    /// System fields
    var sys: Sys { get }
}

extension Resource {
    /// The unique identifier of this Resource
    public var id: String {
        return sys.id
    }

    public var localeCode: String? {
        return sys.locale
    }
}

internal class DeletedResource: Resource, Decodable {

    let sys: Sys

    init(sys: Sys) {
        self.sys = sys
    }
}

/**
 LocalizableResource
 
 Base class for any Resource that has the capability of carrying information for multiple locales.
 If more than one locale is fetched using either `/sync` endpoint, or specifying the wildcard value
 for the locale paramater (i.e ["locale": "*"]) during a fetch, the SDK will cache returned values for 
 all locales. This class gives an interface to specify which locale should be used when fetching data
 from `Resource` instances that are in memory.
 */
public class LocalizableResource: Resource, Decodable {

    /// System fields
    public let sys: Sys

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


    public required init(from decoder: Decoder) throws {

        let container       = try decoder.container(keyedBy: CodingKeys.self)
        let sys             = try container.decode(Sys.self, forKey: .sys)

        guard let localizationContext = decoder.userInfo[DecoderContext.localizationContextKey] as? LocalizationContext else {
            throw SDKError.localeHandlingError(message: """
                SDK failed to find the necessary LocalizationContext
                necessary to properly map API responses to internal format.
                """
            )
        }

        self.localizationContext = localizationContext
        // Get currently selected locale.
        if let localeCode = sys.locale, let locale = localizationContext.locales[localeCode] {
            currentlySelectedLocale = locale
        } else {
            currentlySelectedLocale = localizationContext.default
        }
        self.sys = sys

        let fieldsDictionary = try container.decode(Dictionary<FieldName, Any>.self, forKey: .fields)
        localizableFields = try Localization.fieldsInMultiLocaleFormat(from: fieldsDictionary,
                                                                       selectedLocale: currentlySelectedLocale,
                                                                       wasSelectedOnAPILevel: sys.locale != nil)
    }

    public enum CodingKeys: String, CodingKey {
        case sys
        case fields
    }
}


/// Convenience methods for reading from dictionaries without conditional casts.
public extension Dictionary where Key: ExpressibleByStringLiteral {

    /**
     Extract the String at the specified fieldName.

     - Parameter key: The name of the field to extract the `String` from
     - Returns: The `String` value, or `nil` if data contained is not convertible to a `String`.
     */
    public func string(at key: Key) -> String? {
        return self[key] as? String
    }

    /** 
     Extract the array of `String` at the specified fieldName.
     
     - Parameter key: The name of the field to extract the `[String]` from
     - Returns: The `[String]`, or nil if data contained is not convertible to an `[String]`.
     */
    public func strings(at key: Key) -> [String]? {
        return self[key] as? [String]
    }

    /**
     Extract the `Int` at the specified fieldName.

     - Parameter key: The name of the field to extract the `Int` value from.
     - Returns: The `Int` value, or `nil` if data contained is not convertible to an `Int`.
     */
    public func int(at key: Key) -> Int? {
        return self[key] as? Int
    }

    /**
     Extract the `Date` at the specified fieldName.

     - Parameter key: The name of the field to extract the `Date` value from.
     - Returns: The `Date` value, or `nil` if data contained is not convertible to a `Date`.
     */
    public func int(at key: Key) -> Date? {
        let dateString = self[key] as? String
        let date = dateString?.iso8601StringDate
        return date
    }

    /**
     Extract the `Entry` at the specified fieldName.

     - Parameter key: The name of the field to extract the `Entry` from.
     - Returns: The `Entry` value, or `nil` if data contained does not have contain a Link referencing an `Entry`.
     */
    public func linkedEntry(at key: Key) -> Entry? {
        let link = self[key] as? Link
        let entry = link?.entry
        return entry
    }

    /**
     Extract the `Asset` at the specified fieldName.

     - Parameter key: The name of the field to extract the `Asset` from.
     - Returns: The `Asset` value, or `nil` if data contained does not have contain a Link referencing an `Asset`.
     */
    public func linkedAsset(at key: Key) -> Asset? {
        let link = self[key] as? Link
        let asset = link?.asset
        return asset
    }

    /**
     Extract the `[Entry]` at the specified fieldName.

     - Parameter key: The name of the field to extract the `[Entry]` from.
     - Returns: The `[Entry]` value, or `nil` if data contained does not have contain a Link referencing an `Entry`.
     */
    public func linkedEntries(at key: Key) -> [Entry]? {
        let links = self[key] as? [Link]
        let entries = links?.flatMap { $0.entry }
        return entries
    }

    /**
     Extract the `[Asset]` at the specified fieldName.

     - Parameter key: The name of the field to extract the `[Asset]` from.
     - Returns: The `[Asset]` value, or `nil` if data contained does not have contain a Link referencing an `[Asset]`.
     */
    public func linkedAssets(at key: Key) -> [Asset]? {
        let links = self[key] as? [Link]
        let assets = links?.flatMap { $0.asset }
        return assets
    }

    /**
     Extract the `CLLocationCoordinate2D` at the specified fieldName.

     - Parameter key: The name of the field to extract the `CLLocationCoordinate2D` value from.
     - Returns: The `Bool` value, or `nil` if data contained is not convertible to a `Bool`.
     */
    public func bool(at key: Key) -> Bool? {
        return self[key] as? Bool
    }

    /**
     Extract the `Bool` at the specified fieldName.

     - Parameter key: The name of the field to extract the `Bool` value from.
     - Returns: The `Bool` value, or `nil` if data contained is not convertible to a `Bool`.
     */
    public func location(at key: Key) -> Location? {
        let coordinateJSON = self[key] as? [String: Any]
        guard let longitude = coordinateJSON?["lon"] as? Double else { return nil }
        guard let latitude = coordinateJSON?["lat"] as? Double else { return nil }
        let location = Location(latitude: latitude, longitude: longitude)
        return location
    }

}

// MARK: Internal

extension LocalizableResource: Hashable {
    public var hashValue: Int {
        return id.hashValue
    }
}

extension LocalizableResource: Equatable {}
public func == (lhs: LocalizableResource, rhs: LocalizableResource) -> Bool {
    return lhs.id == rhs.id && lhs.sys.updatedAt == rhs.sys.updatedAt
}


internal func +=<K, V> (left: [K: V], right: [K: V]) -> [K: V] {
    var result = left
    right.forEach { (key, value) in result[key] = value }
    return result
}

internal func +<K, V> (left: [K: V], right: [K: V]) -> [K: V] {
    return left += right
}
