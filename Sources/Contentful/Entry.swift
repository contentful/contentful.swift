//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/**
 Classes conforming to this protocol can be passed into your Client instance so that fetch methods
 asynchronously returning MappedCollection can be used and classes of your own definition can be returned.

 It's important to note that there is no special handling of locales so if using the locale=* query parameter,
 you will need to implement the special handing in your `init(from decoder: Decoder) throws` initializer for your class.

 Example:

 ```
 func fetchMappedEntries(with query: Query<Cat>,
 then completion: @escaping ResultsHandler<MappedArrayResponse<Cat>>) -> URLSessionDataTask?
 ```
 */
public protocol EntryDecodable: FlatResource, Decodable, EndpointAccessible {
    /// The identifier of the Contentful content type that will map to this type of `EntryPersistable`
    static var contentTypeId: ContentTypeId { get }
}

public extension EndpointAccessible where Self: EntryDecodable {
    static var endpoint: Endpoint {
        return Endpoint.entries
    }
}

/// An Entry represents a typed collection of data in Contentful
public class Entry: LocalizableResource {

    /// A convenience subscript operator to access the fields dictionary directly and return a String?
    public subscript(key: String) -> String? {
        return fields[key] as? String
    }

    /// A convenience subscript operator to access the fields dictionary directly and return an Int?
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

                    let unresolvedLinks = mixedLinks.filter { $0.isResolved == false }
                    let newlyResolvedLinks = unresolvedLinks.map { $0.resolve(against: includedEntries, and: includedAssets) }

                    let resolvedLinks = alreadyResolvedLinks + newlyResolvedLinks
                    resolvedLocalizableFieldMap[localeCode] = resolvedLinks
                }

                // Resolve links for structured text fields.
                if let value = fieldValueForLocaleCode as? Document {
                    let embeddedEntryNodes: [Node] = value.content.map { node in
                        if let blockNode = node as? EmbeddedResource {
                            let resolvedTarget = blockNode.data.target.resolve(against: includedEntries, and: includedAssets)
                            let newData = EmbeddedResourceData(resolvedTarget: resolvedTarget)
                            let newBlockNode = EmbeddedResource(resolvedData: newData, nodeType: blockNode.nodeType, content: blockNode.content)
                            return newBlockNode
                        }
                        return node
                    }
                    let newDocument = Document(content: embeddedEntryNodes)
                    resolvedLocalizableFieldMap[localeCode] = newDocument
                }
            }
            localizableFields[fieldName] = resolvedLocalizableFieldMap
        }

        self.localizableFields = localizableFields
    }
}

extension Entry: EndpointAccessible {

    public static let endpoint = Endpoint.entries
}

extension Entry: ResourceQueryable {

    /// The QueryType for an EntryQuery is Query.
    public typealias QueryType = Query
}
