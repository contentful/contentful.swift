
//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/**
 WOOOO! ok so then to resolve a link you just

 if let entry.link? {
 resolveLink or resolveLinkCallback()
 }

 then the api to do the mapping is to just retruns the Entry's instead of the fields, and then

 the mapping looks like let name = entry.fields.

 make protocol Fields that is just thin wrapper to allows clients to access stuff themselves

 make ClientFields implement Decodable or mappable as a constraint

 enforce in the ContentModel protocol to have a sys and a fields which are both protocol types
 */


/// An Entry represents a typed collection of data in Contentful
public class Entry: Resource, LocalizedResource {

    /// Content fields
    public var fields: [String: Any]! {
        // FIXME: Defaults.locale???
        return Contentful.fields(localizedFields, forLocale: sys.locale ?? Defaults.locale, defaultLocale: defaultLocale)
    }

    // Locale to Field mapping.
    var localizedFields: [String: [String: Any]]!

    var defaultLocale: String!

    // Empty intializer
    override init() {}

    init(sys: Sys, localizedFields: [String: [String: Any]], defaultLocale: String) {
        super.init()
        self.sys = sys
        self.localizedFields = localizedFields
        self.defaultLocale = defaultLocale
    }

    convenience init(entry: Entry, localizedFields: [String: [String: Any]]) {
        self.init(sys: entry.sys,
            localizedFields: localizedFields,
            defaultLocale: entry.defaultLocale)
    }

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

    // MARK: StaticMappable

    override public class func objectForMapping(map: Map) -> BaseMappable? {
        let entry = Entry()
        entry.mapping(map: map)
        return entry
    }

    override public func mapping(map: Map) {
        super.mapping(map: map)
        // FIXME:
        let (_, localizedFields) = try! parseLocalizedFields(map.JSON)

        self.localizedFields     = localizedFields
        self.defaultLocale       = determineDefaultLocale(map.JSON)
    }
}
