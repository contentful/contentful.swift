//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper


/// An Entry represents a typed collection of data in Contentful
public class Entry: Resource, LocalizedResource {

    /// Content fields
    public var fields: [String: Any]! {
        return Contentful.fields(localizedFields, forLocale: locale, defaultLocale: defaultLocale)
    }

    // Locale to Field mapping.
    var localizedFields: [String: [String: Any]]!

    let defaultLocale: String

    /// Currently selected locale
    public var locale: String

    // MARK: Internal

    internal func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        var localizedFields = [String: [String: Any]]()

        for (locale, entryFields) in self.localizedFields {
            var fields = entryFields

            // If the passed in dictionary contains the Resource we are linking to, link it.
            for (fieldName, fieldValue) in entryFields {

                if let unresolvedLink = Link.link(from: fieldValue), unresolvedLink.isResolved == false {
                    let resolvedLink = unresolvedLink.resolve(against: includedEntries, and: includedAssets)
                    fields[fieldName] = resolvedLink
                    assert(resolvedLink.isResolved)
                }

                // Resolve one-to-many links. We need to account for links that might not have been
                // resolved because of a multiple page sync so we will store a dictionary rather
                // than a Swift object in the link body. The link will be resolved at a later time.

                if let dictionaryRepresentationArray = fieldValue as? [[String: Any]] {

                    let mixedLinks = dictionaryRepresentationArray.flatMap({ Link.link(from: $0) })

                    // The conversion from dictionary representation should only ever happen once
                    let alreadyResolvedLinks = mixedLinks.filter { $0.isResolved == true }
                    assert(alreadyResolvedLinks.count == 0)

                    let unresolvedLinks = mixedLinks.filter { $0.isResolved == false }
                    let newlyResolvedLinks = unresolvedLinks.map { $0.resolve(against: includedEntries, and: includedAssets) }

                    let resolvedLinks = alreadyResolvedLinks + newlyResolvedLinks
                    fields[fieldName] = resolvedLinks
                }
            }

            localizedFields[locale] = fields
        }

        self.localizedFields = localizedFields
    }

    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {
        let (locale, localizedFields) = try parseLocalizedFields(map.JSON)
        self.locale = locale
        self.defaultLocale = determineDefaultLocale(map.JSON)

        try super.init(map: map)

        self.localizedFields = localizedFields

    }
}
