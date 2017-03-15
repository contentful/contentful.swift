
//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/**
    Or encourage each of the users to make their own protocol and extend it.
 
    For example FieldConfiguration {
 
    }
    extension FieldConfiguration {
        var name: String { get set }
    }
 */
public protocol ClientFields {
    
}

public extension ClientFields {
    // TODO: decode from entry
}


public enum Link {

    case asset(Asset)
    case entry(Entry)
    case unresolved(Link.Sys)

    public struct Sys {
        public let id: String
        public let type: String             // TODO: Assert that this is "Link"
        public let linkType: String // "Entry" or "Asset" (-> Easier to resolve with this information.
    }

    var sys: Link.Sys {
        switch self {
        case .unresolved(let sys):
            return sys
        default:
            fatalError() // TODO:
        }
    }

    var id: String {
        switch self {
        case .asset(let asset):
            return asset.sys.id
        case .entry(let entry):
            return entry.sys.id
        case .unresolved(let jsonLink):
            return Contentful.identifier(for: jsonLink)!
        }
    }

    var isResolved: Bool {
        switch self {
        case .unresolved: return false
        case .asset, .entry: return true
        }
    }

    func resolve(against includes: [String: Any]) -> Link {
        switch self {
        case .unresolved(let sys):
            // TODO:
            break
        default:
            fatalError() // TODO: write test to never get here (or throw internal error)
        }
    }

    // TODO:
    func decode<ContentType: ContentModel>() -> ContentType {
        switch self {
        case .asset(let asset):
            let item = ContentType(identifier: asset.sys.id)
            item?.update(with: asset.fields)
        case .entry(let entry):
            let item = ContentType(identifier: entry.sys.id)
            item?.update(with: entry.fields)
        case .unresolved:
            fatalError("Should not try to decode an unresolved link")
        }
    }
}

/**
    add an internal struct Sys to everything, make them be decodable

 */


public struct Sys {

    /// The unique identifier.
    public var id: String!

    // TODO: Document
    public var createdAt: String!
    // TODO: Document
    public var updatedAt: String!

    /// Currently selected locale
    public var locale: String!

    /// Resource type
    public var type: String!

}

    // TODO: all sys fields and methods here, repeat for assets, also add a Link structure

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
public struct Entry: LocalizedResource {


    /// System fields
    public let sys: Sys

    /// Content fields
    public var fields: [String: Any] {
        return Contentful.fields(localizedFields, forLocale: sys.locale, defaultLocale: defaultLocale)
    }

    public func hasUnresolvedLinks() -> Bool {
        // TODO:
        return true
//        fields.reduce??
    }
    // Locale to Field mapping.
    let localizedFields: [String:[String:Any]]

    let defaultLocale: String

    init(sys: Sys, localizedFields: [String: [String: Any]], defaultLocale: String) {
        self.sys = sys
        self.localizedFields = localizedFields
        self.defaultLocale = defaultLocale
    }

    init(entry: Entry, localizedFields: [String:[String:Any]]) {
        self.init(sys: entry.sys,
            localizedFields: localizedFields,
            defaultLocale: entry.defaultLocale)
    }

    // MARK: Internal

    internal func resolveLinks(againstIncludes includes: [String: Resource]) -> Entry {
        var localizedFields = [String: [String: Any]]()

        for (locale, entryFields) in self.localizedFields {
            var fields = entryFields

            // If the passed in dictionary contains the Resource we are linking to, link it.
            for (fieldName, fieldValue) in entryFields {

                if let unresolvedLink = fieldValue as? Link, unresolvedLink.isResolved == false {
                    let resolvedLink = unresolvedLink.resolve(against: includes)
                    fields[fieldName] = resolvedLink
                }

                // Resolve one-to-many links. We need to account for links that might not hae been
                // resolved because of a multiple page sync so we will store a dictionary rather
                // than a Swift object in the link body. The link will be resolved at a later time.
                if let mixedLinks = fieldValue as? [Link] {

                    let unresolvedLinks = mixedLinks.filter { $0.isResolved == false }
                    let resolvedLinks = unresolvedLinks.map { $0.resolve(against: includes) } + mixedLinks.filter { $0.isResolved == true }
                    fields[fieldName] = resolvedLinks
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
        if let link = fieldValue as? Link {
            let include = includes["\(link.sys.linkType)_\(link.sys.id)"]
            return include
        }
        return nil
    }
}
