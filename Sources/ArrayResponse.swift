//
//  ArrayResponse.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import ObjectMapper

/**
 A list of resources in Contentful

 This is the result type for any request of a collection of resources.
**/
public struct ArrayResponse<T: Resource>: ImmutableMappable {

    /// The resources which are part of the given array
    public let items: [T]

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
