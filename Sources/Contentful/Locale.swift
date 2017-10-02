//
//  Decoding.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public typealias LocaleCode = String

/// A Locale represents possible translations for Entry Fields
public class Locale: Decodable {

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

    private enum CodingKeys: String, CodingKey {
        case code
        case isDefault          = "default"
        case name
        case fallbackLocaleCode = "fallbackCode"
    }
}

/**
 The `LocalizationContext` contains meta information about a Space about locales including
 information about which locale is the default, and what the fallback locale chain is.
 
 This contextual information is necessary to intiialize `Entry` and `Asset` instances properly so that
 the correct data is displayed for the currently selected locale. For instance, if a particular field
 for an `Entry` does not have data for the currently selected locale, the SDK will walk the fallback
 chain for this field until a non-null value is found, or full chain has been walked.
 */
public class LocalizationContext {

    /// An ordered collection of locales representing the fallback chain.
    public let locales: [LocaleCode: Locale]

    /// The default locale of the space.
    public let `default`: Locale

    internal init(default: Locale, locales: [Locale]) {
        self.`default` = `default`

        var localeMap = [LocaleCode: Locale]()
        locales.forEach { localeMap[$0.code] = $0 }
        self.locales = localeMap
    }
}

internal struct Localization {

    // Walks down the fallback chain and returns the field values for the specified locale.
    internal static func fields(forLocale locale: Locale?,
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

    // Normalizes fields to have a value for every locale in the space.
    internal static func fieldsInMultiLocaleFormat(from fields: [FieldName: Any],
                                                   selectedLocale: Locale,
                                                   wasSelectedOnAPILevel: Bool) throws -> [FieldName: [LocaleCode: Any]] {

        if wasSelectedOnAPILevel == false { // sanitize.
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
