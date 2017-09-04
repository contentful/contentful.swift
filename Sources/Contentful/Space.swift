//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation


/// A Space represents a collection of Content Types, Assets and Entries in Contentful
public class Space: Resource, Decodable {

    public let sys: Sys

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

    public required init(from decoder: Decoder) throws {
        let container       = try decoder.container(keyedBy: CodingKeys.self)
        sys                 = try container.decode(Sys.self, forKey: .sys)
        name                = try container.decode(String.self, forKey: .name)
        locales             = try container.decode([Locale].self, forKey: .locales)

        guard let defaultLocale = locales.filter({ $0.isDefault }).first else {
            throw SDKError.localeHandlingError(message: "Locale with default == true not found in Space!")
        }
        localizationContext = LocalizationContext(default: defaultLocale, locales: locales)

    }

    private enum CodingKeys: String, CodingKey {
        case sys
        case name
        case locales
    }
}
