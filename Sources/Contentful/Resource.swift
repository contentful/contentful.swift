//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Protocol for resources inside Contentful.
public protocol Resource {

    /// System fields.
    var sys: Sys { get }
}

/// A protocol signifying that a resource's `Sys` property are accessible for lookup from the top level of the instance.
public protocol FlatResource {
    /// The unique identifier of the Resource.
    var id: String { get }

    /// The date representing the last time the Contentful resource was updated.
    var updatedAt: Date? { get }

    /// The date that the Contentful resource was first created.
    var createdAt: Date? { get }

    /// The code of the locale the current resource contains content for.
    var localeCode: String? { get }
}

public extension FlatResource where Self: Resource {
    var id: String {
        return sys.id
    }

    var type: String {
        return sys.type
    }

    var updatedAt: Date? {
        return sys.updatedAt
    }

    var createdAt: Date? {
        return sys.createdAt
    }

    var localeCode: String? {
        return sys.locale
    }
}

/// A protocol enabling strongly typed queries to the Contentful Delivery API via the SDK.
public protocol FieldKeysQueryable {

    /// The `CodingKey` representing the field identifiers/JSON keys for the corresponding content type.
    /// These coding keys should be the same as those used when implementing `Decodable`.
    associatedtype FieldKeys: CodingKey
}


/// Classes conforming to this protocol are accessible via an `Endpoint`.
public protocol EndpointAccessible {
    /// The endpoint that `EndpointAccessible` types are accessible from.
    static var endpoint: Endpoint { get }
}

/// Entities conforming to this protocol have a `QueryType` that the SDK can use to make generic fetch requests.
public protocol ResourceQueryable {
    /// The associated query type.
    associatedtype QueryType: AbstractQuery
}

/// A typealias to improve expressiveness.
public typealias ContentTypeId = String

/// Class to represent the information describing a resource that has been deleted from Contentful.
public class DeletedResource: Resource, FlatResource, Decodable {

    public let sys: Sys

    internal init(sys: Sys) {
        self.sys = sys
    }
}

/// Base class for any Resource that has the capability of carrying information for multiple locales.
/// If more than one locale is fetched using either `/sync` endpoint, or specifying the wildcard value
/// for the locale paramater (i.e "locale=*") during a fetch, the SDK will cache returned values for
/// all locales in moery. This class gives an interface to specify which locale should be used when
/// reading content from `Resource` instances that are in memory.
public class LocalizableResource: Resource, FlatResource, Decodable {

    /// System fields.
    public let sys: Sys

    /// The currently selected locale to use when reading data from the `fields` dictionary.
    public var currentlySelectedLocale: Locale

    /// The fields with content. If there is no value for a field associated with the currently selected `Locale`,
    /// the SDK will walk down fallback chain until a value is found. If there is still no value after
    /// walking the full chain, the field will be omitted from the `fields` dictionary.
    public var fields: [FieldName: Any] {
        return Localization.fields(forLocale: currentlySelectedLocale, localizableFields: localizableFields, localizationContext: localizationContext)
    }

    /// Sets the locale on the Localizable Resource (i.e. an instance of `Asset` or `Entry`)
    /// so that future reads from the `fields` property will return data corresponding
    /// to the specified locale code.
    ///
    /// - Parameter code: The string code for the Locale.
    /// - Returns: `false` if the locale code doesn't correspond to any locales in the space, `true`.
    @discardableResult
    public func setLocale(withCode code: LocaleCode) -> Bool {
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

        guard let localizationContext = decoder.userInfo[.localizationContextKey] as? LocalizationContext else {
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

    /// The keys used when representing a resource in JSON.
    public enum CodingKeys: String, CodingKey {
        /// The JSON key for the sys object.
        case sys
        /// The JSON key for the fields object.
        case fields
    }
}

// MARK: Internal

extension LocalizableResource: Hashable {    

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(sys.updatedAt)
    }
}

extension LocalizableResource: Equatable {

    public static func == (lhs: LocalizableResource, rhs: LocalizableResource) -> Bool {
        return lhs.id == rhs.id && lhs.sys.updatedAt == rhs.sys.updatedAt
    }
}
