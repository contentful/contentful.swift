//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/// A Locale represents possible translations for Entry Fields
public struct Locale: ImmutableMappable {

    /// The unique identifier for this Locale
    public let code: String
    /**
     Whether this Locale is the default (if a Field is not translated in a given Locale, the value of
     the default locale will be returned by the API)
    */
    public let isDefault: Bool
    /// The name of this Locale
    public let name: String

    // MARK: <ImmutableMappable>

    public init(map: Map) throws {
        code        = try map.value("code")
        isDefault   = try map.value("default")
        name        = try map.value("name")
    }
}

/// A Space represents a collection of Content Types, Assets and Entries in Contentful
public class Space: Resource {

    /// Available Locales for this Space
    public let locales: [Locale]

    /// The name of this Space
    public let name: String

    /// Resource type ("Space")
    public var type: String {
        return sys.type
    }

    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {
        locales = try map.value("locales")
        name    = try map.value("name")

        try super.init(map: map)
    }
}
