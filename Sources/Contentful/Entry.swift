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

    /**
     Tries to resolve `Entry`s and `Asset`s which `self` links to.

     Link resolution is currently _NOT_ recursive. Only one level of links are resolved to
     `Entry`s or `Asset`s. Multi-level link resolution can be emulated by calling this
     method on every `Entry` known to the caller.

     E.g. `ArrayResponse` has `includes`, which should all be passed into this method to
     potentially resolve all links in the `ArrayResponse`.

     Links can remain unresolved for at least the following reasons:
     - User narrowed the query to a certain type (e.g. `Entry`) when using the '/sync'
       endpoint, such that the linked content is not in `includedEntries` or `includedAssets`.
     - User set the `Query`'s `includesLevel` too low, such that the linked content is
       not in `includedEntries` or `includedAssets`.

     - parameters:
         - includedEntries: `Entry` candidates that `self` _could_ link to.
         - includedAssets: `Asset` candidates that `self` _could_ link to.
    */
    internal func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        var localizableFields = [FieldName: [LocaleCode: Any]]()

        for (fieldName, localizableFieldMap) in self.localizableFields {
            // Mutable copy.
            var resolvedLocalizableFieldMap = localizableFieldMap

            // Iterate all field values in this localizableField and resolve
            // those that are of type Link.
            for (localeCode, fieldValueForLocaleCode) in localizableFieldMap {

                switch fieldValueForLocaleCode {
                case let oneToOneLink as Link where oneToOneLink.isResolved == false:
                    let resolvedLink = oneToOneLink.resolve(against: includedEntries, and: includedAssets)
                    resolvedLocalizableFieldMap[localeCode] = resolvedLink
                case let oneToManyLinks as [Link]:
                    let resolvedLinks = oneToManyLinks.map { link -> Link in
                        if link.isResolved {
                            return link
                        } else {
                            return link.resolve(against: includedEntries, and: includedAssets)
                        }
                    }
                    resolvedLocalizableFieldMap[localeCode] = resolvedLinks
                case let recursiveNode as RecursiveNode:
                    recursiveNode.resolveLinks(against: includedEntries, and: includedAssets)
                default:
                    continue
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
