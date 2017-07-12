//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper


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

    /// Context for holding information about the fallback chain of locales for the Space.
    public let localizationContext: LocalizationContext

    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {
        name        = try map.value("name")
        locales     = try map.value("locales")

        guard let defaultLocale = locales.filter({ $0.isDefault }).first else {
            throw SDKError.localeHandlingError(message: "Locale with default == true not found in Space!")
        }
        localizationContext = LocalizationContext(default: defaultLocale, locales: locales)

        try super.init(map: map)
    }
}
