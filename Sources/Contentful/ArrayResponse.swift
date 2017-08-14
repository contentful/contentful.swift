//
//  ArrayResponse.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import ObjectMapper


private protocol Array {

    associatedtype ItemType

    var items: [ItemType] { get }

    var limit: UInt { get }

    var skip: UInt { get }

    var total: UInt { get }
}

/**
 A list of resources in Contentful

 This is the result type for any request of a collection of resources.
 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
**/
public struct ArrayResponse<ItemType>: Array, ImmutableMappable where ItemType: Resource {

    /// The resources which are part of the given array
    public let items: [ItemType]

    /// The maximum number of resources originally requested
    public let limit: UInt

    /// The number of elements skipped when performing the request
    public let skip: UInt

    /// The total number of resources which matched the original request
    public let total: UInt

    internal let includedAssets: [Asset]?
    internal let includedEntries: [Entry]?

    // MARK: <ImmutableMappable>

    public init(map: Map) throws {

        items           = try map.value("items")
        limit           = try map.value("limit")
        skip            = try map.value("skip")
        total           = try map.value("total")

        includedAssets  = try? map.value("includes.Asset")
        includedEntries = try? map.value("includes.Entry")

        // Annoying workaround for type system not allowing cast of items to [Entry]
        let entries: [Entry] = items.flatMap { $0 as? Entry }

        let allIncludedEntries = entries + (includedEntries ?? [])

        // Rememember `Entry`s are classes (passed by reference) so we can change them in place
        for entry in allIncludedEntries {
            entry.resolveLinks(against: allIncludedEntries, and: (includedAssets ?? []))
        }
    }
}

/**
 A list of Contentful entries that have been mapped to types conforming to `EntryModellable`

 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
 */
public struct MappedArrayResponse<ItemType>: Array where ItemType: EntryModellable {

    /// The resources which are part of the given array
    public let items: [ItemType]

    /// The maximum number of resources originally requested
    public let limit: UInt

    /// The number of elements skipped when performing the request
    public let skip: UInt

    /// The total number of resources which matched the original request
    public let total: UInt
}
