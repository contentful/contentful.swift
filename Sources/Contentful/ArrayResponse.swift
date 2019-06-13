//
//  ArrayResponse.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

private protocol Array {

    var limit: UInt { get }

    var skip: UInt { get }

    var total: UInt { get }

    var errors: [ArrayResponseError]? { get }
}

internal enum ArrayCodingKeys: String, CodingKey {
    case items, includes, skip, limit, total, errors
}

private protocol HomogeneousArray: Array {

    associatedtype ItemType

    var items: [ItemType] { get }
}

/// Sometimes, when links are unresolvable (for instance, when a linked entry is not published), the API
/// will return an array of errors, one for each unresolvable link.
public struct ArrayResponseError: Decodable {
    /// The system fields of the error.
    public struct Sys: Decodable {
        /// The identifer of the error.
        public let id: String
        /// The type identifier for the error.
        public let type: String
    }

    /// System fields for the unresolvable link.
    public let details: Link.Sys
    /// System fields describing the type of this object ("error") and the error message: generally "notResolvable".
    public let sys: ArrayResponseError.Sys
}

/// A list of resources in Contentful
/// This is the result type for any request of a collection of resources.
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
public struct HomogeneousArrayResponse<ItemType>: HomogeneousArray where ItemType: Decodable & EndpointAccessible {

    /// The resources which are part of the array response.
    public let items: [ItemType]

    /// The maximum number of resources originally requested.
    public let limit: UInt

    /// The number of elements skipped when performing the request.
    public let skip: UInt

    /// The total number of resources which matched the original request.
    public let total: UInt

    /// An array of errors, or partial errors, which describe links which were returned in the response that
    /// cannot be resolved.
    public let errors: [ArrayResponseError]?

    internal let homogeneousIncludes: Includes?
    internal let heterogeneousIncludes: HeterogeneousIncludes?

    internal var includedAssets: [Asset]? {
        return homogeneousIncludes?.assets
    }
    internal var includedEntries: [Entry]? {
        return homogeneousIncludes?.entries
    }

    internal struct Includes: Decodable {
        internal let assets: [Asset]?
        internal let entries: [Entry]?

        private enum CodingKeys: String, CodingKey {
            case assets     = "Asset"
            case entries    = "Entry"
        }

        internal init(from decoder: Decoder) throws {
            let values  = try decoder.container(keyedBy: CodingKeys.self)
            assets      = try values.decodeIfPresent([Asset].self, forKey: .assets)
            entries     = try values.decodeIfPresent([Entry].self, forKey: .entries)
        }
    }
}

@available(*, deprecated, message: "Use HomogeneousArrayResponse instead")
public typealias ArrayResponse = HomogeneousArrayResponse

extension HomogeneousArrayResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: ArrayCodingKeys.self)

        skip            = try container.decode(UInt.self, forKey: .skip)
        total           = try container.decode(UInt.self, forKey: .total)
        limit           = try container.decode(UInt.self, forKey: .limit)
        errors          = try container.decodeIfPresent([ArrayResponseError].self, forKey: .errors)

        // If ItemType conforms to EntryDecodable, we can strongly assume that self
        // contains items of a user-defined type.
        let areItemsOfCustomType = ItemType.self is EntryDecodable.Type

        if areItemsOfCustomType {

            // Since self's items are of a custom (i.e. user-defined) type,
            // we must accomodate the scenario that included Entries are
            // heterogeneous, since items can link to whatever custom Entries
            // the user defined.
            // As a consequence, we have to use the LinkResolver in order to
            // establish links among items and included Entries and/or Assets.

            // All items and includes.
            homogeneousIncludes = nil
            heterogeneousIncludes = try container.decodeIfPresent(HeterogeneousIncludes.self, forKey: .includes)

            // A copy as an array of dictionaries just to extract "sys.type" field.
            guard let jsonItems = try container.decode(Swift.Array<Any>.self, forKey: .items) as? [[String: Any]] else {
                let errorMessage = "SDK was unable to serialize returned resources"
                throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
            }

            var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .items)
            var entries: [EntryDecodable] = []

            let contentTypes = decoder.userInfo[.contentTypesContextKey] as? [ContentTypeId: EntryDecodable.Type]

            while !entriesJSONContainer.isAtEnd {
                guard let contentTypeInfo = jsonItems.contentTypeInfo(at: entriesJSONContainer.currentIndex) else {
                    let errorMessage = "SDK was unable to parse sys.type property necessary to finish resource serialization."
                    throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
                }

                // Throw an error in this case as if there is no matching content type for the current id, then
                // we can't serialize any of the entries. The type must match ItemType as this is a homogenous array.
                guard let entryDecodableType = contentTypes?[contentTypeInfo.id], entryDecodableType == ItemType.self else {
                    let errorMessage = """
                    A response for the QueryOn<\(ItemType.self)> did return successfully, but a serious error occurred when decoding the array of \(ItemType.self).
                    Double check that you are passing \(ItemType.self).self, and references to all other EntryDecodable classes into the Client initializer.
                    """
                    throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
                }
                let entryDecodable = try entryDecodableType.popEntryDecodable(from: &entriesJSONContainer)
                entries.append(entryDecodable)
            }

            // Workaround for type system not allowing cast of items to [ItemType].
            self.items = entries.compactMap { $0 as? ItemType }

            // Cache to enable link resolution.
            decoder.linkResolver.cache(entryDecodables: self.items as! [EntryDecodable])

            // Resolve links.
            decoder.linkResolver.churnLinks()
        } else {

            // Since self's items are NOT of a custom (i.e. user-defined) type,
            // we can assume that they are of one of the known concrete types in this SDK.
            // Consequently, the included/embedded contents are all either of type Entry
            // or Asset, and links pointing to them can be resolved with a simpler
            // approach than using the LinkResolver.

            heterogeneousIncludes   = nil
            homogeneousIncludes     = try container.decodeIfPresent(Includes.self, forKey: .includes)
            items                   = try container.decode([ItemType].self, forKey: .items)

            // If the ItemType was Entry, filter those entries so we can resolve their links.
            let entries: [Entry] = items.compactMap { $0 as? Entry }

            let allIncludedEntries = entries + (includedEntries ?? [])

            // Rememember `Entry`s are classes (passed by reference) so we can change them in place.
            for entry in allIncludedEntries {
                entry.resolveLinks(against: allIncludedEntries, and: (includedAssets ?? []))
            }
        }
    }

    fileprivate enum CodingKeys: String, CodingKey {
        case items, includes, skip, limit, total, errors
    }
}

/**
 Container for includes within a
 */
internal struct HeterogeneousIncludes: Decodable {
    internal let assets: [Asset]?
    internal let entries: [EntryDecodable]?

    private enum CodingKeys: String, CodingKey {
        case assets     = "Asset"
        case entries    = "Entry"
    }

    internal init(from decoder: Decoder) throws {
        let container       = try decoder.container(keyedBy: CodingKeys.self)
        assets              = try container.decodeIfPresent([Asset].self, forKey: .assets)
        entries             = try container.decodeHeterogeneousEntries(forKey: .entries,
                                                                       contentTypes: decoder.contentTypes,
                                                                       throwIfNotPresent: false)
        // Cache to enable link resolution.
        if let assets = assets {
            decoder.linkResolver.cache(assets: assets)
        }
        // Cache to enable link resolution.
        if let entries = entries {
            decoder.linkResolver.cache(entryDecodables: entries)
        }
    }
}

/// A list of Contentful entries that have been mapped to types conforming to `EntryDecodable` instances.
/// A `HeterogeneousArrayResponse` respresents a heterogeneous collection of `EntryDecodable` being returned,
/// for instance, if hitting the base `/entries` endpoint with no additional query parameters. If there is no
/// user-defined type for a particular entry, that entry will not be deserialized at all. It is up to you to
/// introspect the type of each element in the items array to handle the response data properly.
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
public struct HeterogeneousArrayResponse: Array {

    /// The resources which are part of the given array response.
    public let items: [EntryDecodable]

    /// The maximum number of resources originally requested
    public let limit: UInt

    /// The number of elements skipped when performing the request.
    public let skip: UInt

    /// The total number of resources which matched the original request.
    public let total: UInt

    /// An array of errors, or partial errors, which describe links which were returned in the response that
    /// cannot be resolved.
    public let errors: [ArrayResponseError]?

    internal let includes: HeterogeneousIncludes?

    internal var includedAssets: [Asset]? {
        return includes?.assets
    }
    internal var includedEntries: [EntryDecodable]? {
        return includes?.entries
    }
}

@available(*, deprecated, message: "Use HeterogeneousArrayResponse instead")
public typealias MixedArrayResponse = HeterogeneousArrayResponse

extension HeterogeneousArrayResponse: Decodable {

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: ArrayCodingKeys.self)
        skip            = try container.decode(UInt.self, forKey: .skip)
        total           = try container.decode(UInt.self, forKey: .total)
        limit           = try container.decode(UInt.self, forKey: .limit)
        errors          = try container.decodeIfPresent([ArrayResponseError].self, forKey: .errors)

        // All items and includes.
        includes        = try container.decodeIfPresent(HeterogeneousIncludes.self, forKey: .includes)
        items           = try container.decodeHeterogeneousEntries(forKey: .items,
                                                                   contentTypes: decoder.contentTypes,
                                                                   throwIfNotPresent: true) ?? []

        // Cache to enable link resolution.
        decoder.linkResolver.cache(entryDecodables: self.items)

        // Resolve links.
        decoder.linkResolver.churnLinks()
    }
}

// Convenience method for grabbing the content type information of a json item in an array of resources.
internal extension Swift.Array where Element == Dictionary<String, Any> {

    func contentTypeInfo(at index: Int) -> Link? {
        guard let sys = self[index]["sys"] as? [String: Any], let contentTypeInfo = sys["contentType"] as? Link else {
            return nil
        }
        return contentTypeInfo
    }

    func nodeType(at index: Int) -> NodeType? {
        guard let nodeTypeString = self[index]["nodeType"] as? String, let nodeType = NodeType(rawValue: nodeTypeString) else {
            return nil
        }
        return nodeType
    }
}

// Empty type so that we can continue to the end of a UnkeyedContainer
internal struct EmptyDecodable: Decodable {}

extension KeyedDecodingContainer {

    internal func decodeHeterogeneousEntries(forKey key: K,
                                             contentTypes: [ContentTypeId: EntryDecodable.Type],
                                             throwIfNotPresent: Bool) throws -> [EntryDecodable]? {


        guard let itemsAsDictionaries = try self.decodeIfPresent(Swift.Array<Any>.self, forKey: key) as? [[String: Any]] else {
            if throwIfNotPresent {
                throw SDKError.unparseableJSON(data: nil, errorMessage: "SDK was unable to deserialize returned resources")
            } else {
                return nil
            }
        }
        var entriesJSONContainer = try self.nestedUnkeyedContainer(forKey: key)

        var entries: [EntryDecodable] = []
        while !entriesJSONContainer.isAtEnd {

            guard let contentTypeInfo = itemsAsDictionaries.contentTypeInfo(at: entriesJSONContainer.currentIndex) else {
                let errorMessage = "SDK was unable to parse the `sys.contentType` property necessary to finish resource serialization."
                throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
            }

            // For includes, if the type of this entry isn't defined by the user, we skip serialization.
            if let type = contentTypes[contentTypeInfo.id] {
                let entryModellable = try type.popEntryDecodable(from: &entriesJSONContainer)
                entries.append(entryModellable)
            } else {
                // Another annoying workaround: there is no mechanism for incrementing the `currentIndex` of an
                // UnkeyedCodingContainer other than actually decoding an item
                _ = try? entriesJSONContainer.decode(EmptyDecodable.self)
            }
        }
        return entries
    }

}
