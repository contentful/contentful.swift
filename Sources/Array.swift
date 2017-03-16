//
//  Array.swift
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
public struct Array<T: Resource>: StaticMappable {
    /**
     Optional list of errors which happened while fetching this result.

     For example, information about references which could not be resolved.
    */
    public let errors: [Error]? = nil

    /// The resources which are part of the given array
    public var items: [T]!

    internal var includedAssets: [Asset]?
    internal var includedEntries: [Entry]?

    /// The maximum number of resources originally requested
    public var limit: UInt!
    /// The number of elements skipped when performing the request
    public var skip: UInt!
    /// The total number of resources which matched the original request
    public var total: UInt!


    // MARK: StaticMappable

    public static func objectForMapping(map: Map) -> BaseMappable? {
        var array = Contentful.Array()
        array.mapping(map: map)
        return array
    }

    public mutating func mapping(map: Map) {
        items               <- map["items"]
        includedAssets      <- map["includes.Asset"]
        includedEntries     <- map["includes.Entry"]
        limit               <- map["limit"]
        skip                <- map["skip"]
        total               <- map["total"]

        // Annoying workaround for type system not allowing cast to [Entry]
        // If the entry was in the original
        let entries: [Entry] = items.flatMap { $0 as? Entry }
        let allIncludedEntries = entries + (includedEntries ?? [])
        for entry in entries {
            entry.resolveLinks(against: allIncludedEntries, and: includedAssets)
        }

    }
}
