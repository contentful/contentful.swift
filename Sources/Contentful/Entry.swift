//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Classes conforming to this protocol can be passed into your `Client` instance so that fetch methods
/// returning may decode the JSON to your own classes before returning them in async callbacks.
///
/// It's important to note that there is no special handling of locales so if using the locale=* query parameter,
/// you will need to implement the special handing in your `init(from decoder: Decoder) throws` initializer for your class.
///
/// Example:
///
/// ```
/// func fetchArray(of: Cat.self, matching: QueryON<Cat>,
/// then completion: @escaping ResultsHandler<MappedArrayResponse<Cat>>) -> URLSessionDataTask?
/// ```
public protocol EntryDecodable: FlatResource, Decodable, EndpointAccessible {
    /// The identifier of the Contentful content type that will map to this type of `EntryPersistable`
    static var contentTypeId: ContentTypeId { get }
}

public extension EndpointAccessible where Self: EntryDecodable {
    static var endpoint: Endpoint {
        return Endpoint.entries
    }
}

/// An `Entry` represents a typed collection of content, structured via fields, in Contentful.
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
                    let resolvedLinks = mixedLinks.map { (link) -> Link in
                        if link.isResolved {
                            return link
                        } else {
                            return link.resolve(against: includedEntries, and: includedAssets)
                        }
                    }
                    resolvedLocalizableFieldMap[localeCode] = resolvedLinks
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
