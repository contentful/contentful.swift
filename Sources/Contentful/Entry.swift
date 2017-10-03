//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// An Entry represents a typed collection of data in Contentful
public class Entry: LocalizableResource {

    public var localeCode: String {
        return sys.locale!
    }

    public subscript(key: String) -> String? {
        return fields[key] as? String
    }

    public subscript(key: String) -> Int? {
        return fields[key] as? Int
    }

    // MARK: Internal

    internal func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        var localizableFields = [FieldName: [LocaleCode: Any]]()

        for (fieldName, localizableFieldMap) in self.localizableFields {
            // Mutable copy.
            var resolvedLocalizableFieldMap = localizableFieldMap

            for (localeCode, fieldValueForLocaleCode) in localizableFieldMap {

                if let unresolvedLink = fieldValueForLocaleCode as? Link, unresolvedLink.isResolved == false {
                    let resolvedLink = unresolvedLink.resolve(against: includedEntries, and: includedAssets)
                    // Technically it's possible that the link is still unresolved at this point:
                    // for instance if a user specify type=Entry when using the '/sync' endpoint
                    resolvedLocalizableFieldMap[localeCode] = resolvedLink
                }

                // Resolve one-to-many links. We need to account for links that might not have been
                // resolved because of a multiple page sync so we will store a dictionary rather
                // than a Swift object in the link body. The link will be resolved at a later time.

                if let mixedLinks = fieldValueForLocaleCode as? [Link] {

                    // The conversion from dictionary representation should only ever happen once
                    let alreadyResolvedLinks = mixedLinks.filter { $0.isResolved == true }
                    assert(alreadyResolvedLinks.count == 0)

                    let unresolvedLinks = mixedLinks.filter { $0.isResolved == false }
                    let newlyResolvedLinks = unresolvedLinks.map { $0.resolve(against: includedEntries, and: includedAssets) }

                    let resolvedLinks = alreadyResolvedLinks + newlyResolvedLinks
                    resolvedLocalizableFieldMap[localeCode] = resolvedLinks
                }
            }
            localizableFields[fieldName] = resolvedLocalizableFieldMap
        }

        self.localizableFields = localizableFields
    }
}
