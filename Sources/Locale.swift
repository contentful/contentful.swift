//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

public typealias LocaleCode = String

/// A Locale represents possible translations for Entry Fields
public class Locale: ImmutableMappable {

    /// Linked list accessor for going to the next fallback locale
    public let fallbackLocaleCode: LocaleCode?

    /// The unique identifier for this Locale
    public let code: LocaleCode
    /**
     Whether this Locale is the default (if a Field is not translated in a given Locale, the value of
     the default locale will be returned by the API)
     */
    public let isDefault: Bool
    /// The name of this Locale
    public let name: String

    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {
        code                = try map.value("code")
        isDefault           = try map.value("default")
        name                = try map.value("name")

        // Fallback locale code isn't always present.
        var fallbackLocaleCode: LocaleCode?
        fallbackLocaleCode <- map["fallbackCode"]
        self.fallbackLocaleCode = fallbackLocaleCode
    }
}

internal class LocalizationContext: MapContext {

    // An ordered collection of locales representing the fallback chain.
    let locales: [LocaleCode: Locale]

    let `default`: Locale

    init(default: Locale, locales: [Locale]) {
        self.`default` = `default`

        var localeMap = [LocaleCode: Locale]()
        locales.forEach { localeMap[$0.code] = $0 }
        self.locales = localeMap
    }
}

internal struct Localization {

    // Walk down the fallback chain bla bla bla
    static func fields(forLocale locale: Locale?,
                       localizableFields: [FieldName: [LocaleCode: Any]],
                       localizationContext: LocalizationContext) -> [FieldName: Any] {

        // If no locale passed in, use the default.
        let originalLocale = locale ?? localizationContext.default

        var fields = [FieldName: Any]()
        for (fieldName, localesToFieldValues) in localizableFields {

            // Reset to the original locale.
            var currentLocale = originalLocale

            // While there is no localized value for a particular locale, get the next locale.
            while localesToFieldValues[currentLocale.code] == nil {

                // Break loops if we've walked through all of the locales.
                guard let fallbackLocaleCode = currentLocale.fallbackLocaleCode else { break }

                // Go to the next locale.
                if let fallbackLocale = localizationContext.locales[fallbackLocaleCode] {
                    currentLocale = fallbackLocale
                }
            }
            // Assign the value, if it exists.
            if let fieldValue = localesToFieldValues[currentLocale.code] {
                fields[fieldName] = fieldValue
            }
        }
        return fields
    }

    // Should localized fields
    internal static func mapFieldsToMultiLocaleFormat(using map: Map,
                                                      selectedLocale: Locale) throws -> [FieldName: [LocaleCode: Any]] {
        let fields: [FieldName: Any] = try map.value("fields")

        var firstLocaleForThisResource: LocaleCode?
        // For locale=* and /sync, this property will not be present.
        firstLocaleForThisResource <- map["sys.locale"]
        if firstLocaleForThisResource == nil { // sanitize.

            // If there was no locale it the response, then we have the format with all locales present and we can simply map from localecode to locale and exit
            guard let fields = fields as? [FieldName: [LocaleCode: Any]] else {
                throw SDKError.localeHandlingError(message: "Unexpected response format: 'sys.locale' not present, and"
                + "individual fields dictionary is not in localizable format. i.e. 'title: { en-US: englishValue, de-DE: germanValue }'")
            }
            return fields
        }

        // Init container for our own format.
        var localizableFields = [FieldName: [LocaleCode: Any]]()

        for (fieldName, fieldValue) in fields {
            localizableFields[fieldName] = [selectedLocale.code: fieldValue]
        }
        return localizableFields
    }
}
