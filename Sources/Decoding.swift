//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

private var key = "ContentfulClientKey"

internal func determineDefaultLocale(client: Client?) -> String {
    if let space = client?.space {
        if let locale = (space.locales.filter { $0.isDefault }).first {
            return locale.code
        }
    }

    return Defaults.locale
}

internal func parseLocalizedFields(_ json: [String: Any]) throws -> (String?, [String: [String: Any]]) {
    let map = Map(mappingType: .fromJSON, JSON: json)
    var fields: [String: Any]!
    fields <- map["fields"]

    var locale: String?
    locale <- map["sys.locale"]

    var localizedFields = [String: [String: Any]]()

    // If there is a locale field, we still want to represent the field internally with a
    // localization mapping.
    if let locale = locale {
        localizedFields[locale] = fields
    } else {

        // In the case that the fields have been returned with the wildcard format `locale=*`
        // Therefore the structure of fieldsWithDates is [String: [String: Any]]
        fields.forEach { fieldName, localizableFields in
            if let fields = localizableFields as? [String: Any] {
                fields.forEach { locale, value in
                    if localizedFields[locale] == nil {
                        localizedFields[locale] = [String: Any]()
                    }
                    localizedFields[locale]?[fieldName] = value
                }
            }
        }
    }

    return (locale, localizedFields)
}
