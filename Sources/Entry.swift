//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// An Entry represents a typed collection of data in Contentful
public struct Entry : Resource, LocalizedResource {
    /// System fields
    public let sys: [String:AnyObject]
    
    /// Content fields
    public var fields: [String:Any] {
        return Contentful.fields(localizedFields, forLocale: locale, defaultLocale: defaultLocale)
    }

    // Locale to Field mapping.
    private(set) var localizedFields: [String:[String:Any]]

    let defaultLocale: String

    /// The unique identifier of this Entry
    public let identifier: String
    /// Resource type ("Entry")
    public let type: String

    /// Currently selected locale
    public var locale: String

    init(sys: [String:AnyObject], localizedFields: [String:[String:Any]], defaultLocale: String,
            identifier: String, type: String, locale: String) {
        self.sys = sys
        self.localizedFields = localizedFields
        self.identifier = identifier
        self.type = type
        self.locale = locale
        self.defaultLocale = defaultLocale
    }

    init(entry: Entry, localizedFields: [String:[String:Any]]) {
        self.init(sys: entry.sys,
            localizedFields: localizedFields,
            defaultLocale: entry.defaultLocale,
            identifier: entry.identifier,
            type: entry.type,
            locale: entry.locale)
    }

    // MARK: Internal

    internal func resolveLinks(againstIncludes includes: [String:Resource]) -> Entry {
        var localizedFields = [String:[String:Any]]()

        for (locale, entryFields) in self.localizedFields {
            var fields = entryFields

            // If the passed in dictionary contains the Resource we are linking to, link it.
            for (fieldName, fieldValue) in entryFields {

                // Resolve one-to-one links.
                if let resolvedLink = resolve(jsonFieldValue: fieldValue, againstIncludes: includes) {
                    fields[fieldName] = resolvedLink
                }

                // Resolve one-to-many links. Some links may have already been during
                // decoding, so we
                if let linksToResolve = fieldValue as? [[String:AnyObject]] {
                    
                    // An array of both resolved and unresolved links.
                    var links = [Any]()

                    for unresolvedLink in linksToResolve {

                        if let resolvedLink = resolve(jsonFieldValue: unresolvedLink, againstIncludes: includes) {
                            links.append(resolvedLink)
                        } else {
                            links.append(unresolvedLink)
                        }
                    }
                    fields[fieldName] = links
                }
            }

            localizedFields[locale] = fields
        }

        return Entry(entry: self, localizedFields: localizedFields)
    }

    // Returns the included object/structure to be linked by looking up via typename_identifier.
    // Client usage should attempt to unrwap before storing.
    private func resolve(jsonFieldValue fieldValue: Any, againstIncludes includes: [String:Resource]) -> Resource? {

        // Linked objects are stored as a dictionary with "type": "Link",
        // value for "linkType" can be "Asset", "Entry", "Space", "ContentType".
        if let link = fieldValue as? [String:AnyObject],
            sys = link["sys"] as? [String:AnyObject],
            identifier = sys["id"] as? String,
            type = sys["linkType"] as? String,
            include = includes["\(type)_\(identifier)"] {
                return include
        }
        return nil
    }
}
