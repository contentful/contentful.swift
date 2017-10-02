//
//  ArrayResponse.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

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
public struct ArrayResponse<ItemType>: Array where ItemType: Resource, ItemType: Decodable {

    /// The resources which are part of the given array
    public let items: [ItemType]

    /// The maximum number of resources originally requested
    public let limit: UInt

    /// The number of elements skipped when performing the request
    public let skip: UInt

    /// The total number of resources which matched the original request
    public let total: UInt

    internal let includes: Includes?

    internal var includedAssets: [Asset]? {
        return includes?.assets
    }
    internal var includedEntries: [Entry]? {
        return includes?.entries
    }

    internal struct Includes: Decodable {
        let assets: [Asset]?
        let entries: [Entry]?

        private enum CodingKeys: String, CodingKey {
            case assets     = "Asset"
            case entries    = "Entry"
        }

        init(from decoder: Decoder) throws {
            let values  = try decoder.container(keyedBy: CodingKeys.self)
            assets      = try values.decodeIfPresent([Asset].self, forKey: CodingKeys.assets)
            entries     = try values.decodeIfPresent([Entry].self, forKey: CodingKeys.entries)
        }
    }
}


extension ArrayResponse: Decodable {
    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        items           = try container.decode([ItemType].self, forKey: .items)
        includes        = try container.decodeIfPresent(ArrayResponse.Includes.self, forKey: .includes)
        skip            = try container.decode(UInt.self, forKey: .skip)
        total           = try container.decode(UInt.self, forKey: .total)
        limit           = try container.decode(UInt.self, forKey: .limit)

        // Annoying workaround for type system not allowing cast of items to [Entry]
        let entries: [Entry] = items.flatMap { $0 as? Entry }

        let allIncludedEntries = entries + (includedEntries ?? [])

        // Rememember `Entry`s are classes (passed by reference) so we can change them in place
        for entry in allIncludedEntries {
            entry.resolveLinks(against: allIncludedEntries, and: (includedAssets ?? []))
        }
    }
    private enum CodingKeys: String, CodingKey {
        case items, includes, skip, limit, total
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
