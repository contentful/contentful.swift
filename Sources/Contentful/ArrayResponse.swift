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
}

private protocol HomogeneousArray: Array {

    associatedtype ItemType

    var items: [ItemType] { get }
}

/**
 A list of resources in Contentful

 This is the result type for any request of a collection of resources.
 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
 **/
public struct ArrayResponse<ItemType>: HomogeneousArray where ItemType: Resource & Decodable {

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
public struct DecodedEntriesArrayResponse<ItemType>: HomogeneousArray where ItemType: EntryDecodable {

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
    internal var includedEntries: [EntryDecodable]? {
        return includes?.entries
    }

    internal struct Includes: Decodable {
        let assets: [Asset]?
        let entries: [EntryDecodable]?

        private enum CodingKeys: String, CodingKey {
            case assets     = "Asset"
            case entries    = "Entry"
        }

        init(from decoder: Decoder) throws {
            let container   = try decoder.container(keyedBy: CodingKeys.self)
            let linkResolver = decoder.userInfo[linkResolverContext] as! LinkResolver

            assets          = try container.decodeIfPresent([Asset].self, forKey: CodingKeys.assets)
            if let assets = assets {
                for asset in assets {
                    linkResolver.dataCache.add(asset: asset)
                }
            }

            // A copy as an array of dictionaries just to extract "sys.type" field.
            guard let jsonItems = try container.decodeIfPresent(Swift.Array<Any>.self, forKey: .entries) as? [[String: Any]] else {
                self.entries = nil
                return
            }
            var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .entries)
            var entries: [EntryDecodable] = []

            while entriesJSONContainer.isAtEnd == false {
                guard let sys = jsonItems[entriesJSONContainer.currentIndex]["sys"] as? [String: Any],
                    let contentTypeInfo = sys["contentType"] as? Link else {
                    let errorMessage = "SDK was unable to parse sys.type property necessary to finish resource serialization."
                    throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
                }

                let contentTypes = decoder.userInfo[contentTypesContextKey] as! [ContentTypeId: EntryDecodable.Type]
                // TODO: Throw error instead of force unwrapping?
                let type = contentTypes[contentTypeInfo.id]!
                let entryModellable = try type.makeFrom(container: &entriesJSONContainer)
                entries.append(entryModellable)
            }
            self.entries = entries

            for entry in entries {
                linkResolver.dataCache.add(entry: entry)
            }
        }
    }
}

extension DecodedEntriesArrayResponse: Decodable {

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        skip            = try container.decode(UInt.self, forKey: .skip)
        total           = try container.decode(UInt.self, forKey: .total)
        limit           = try container.decode(UInt.self, forKey: .limit)

        // All items and includes.
        includes        = try container.decodeIfPresent(DecodedEntriesArrayResponse.Includes.self, forKey: .includes)

        // A copy as an array of dictionaries just to extract "sys.type" field.
        guard let jsonItems = try container.decode(Swift.Array<Any>.self, forKey: .items) as? [[String: Any]] else {
            throw SDKError.unparseableJSON(data: nil, errorMessage: "SDK was unable to serialize returned resources")
        }
        var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .items)
        var entries: [EntryDecodable] = []

        while entriesJSONContainer.isAtEnd == false {
            guard let sys = jsonItems[entriesJSONContainer.currentIndex]["sys"] as? [String: Any],
                let contentTypeInfo = sys["contentType"] as? Link else {

                let errorMessage = "SDK was unable to parse sys.type property necessary to finish resource serialization."
                throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
            }

            let contentTypes = decoder.userInfo[contentTypesContextKey] as! [ContentTypeId: EntryDecodable.Type]
            // TODO: Throw error instead of force unwrapping?
            let type = contentTypes[contentTypeInfo.id]!
            let entryModellable = try type.makeFrom(container: &entriesJSONContainer)
            entries.append(entryModellable)
        }

        // Annoying workaround for the typesystem bla bla.
        self.items = entries.flatMap { $0 as? ItemType }

        let linkResolver = decoder.userInfo[linkResolverContext] as! LinkResolver
        for entry in entries {
            linkResolver.dataCache.add(entry: entry)
        }
        decoder.linkResolver.churnLinks()
    }
    private enum CodingKeys: String, CodingKey {
        case items, includes, skip, limit, total
    }
}





/**
 A list of Contentful entries that have been mapped to types conforming to `EntryModellable`

 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
 */
public struct MixedDecodedEntriesArrayResponse: Array {

    /// The resources which are part of the given array
    public let items: [EntryDecodable]

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
    internal var includedEntries: [EntryDecodable]? {
        return includes?.entries
    }

    internal struct Includes: Decodable {
        let assets: [Asset]?
        let entries: [EntryDecodable]?

        private enum CodingKeys: String, CodingKey {
            case assets     = "Asset"
            case entries    = "Entry"
        }

        init(from decoder: Decoder) throws {
            let container   = try decoder.container(keyedBy: CodingKeys.self)
            let linkResolver = decoder.userInfo[linkResolverContext] as! LinkResolver

            assets          = try container.decodeIfPresent([Asset].self, forKey: CodingKeys.assets)
            if let assets = assets {
                for asset in assets {
                    linkResolver.dataCache.add(asset: asset)
                }
            }

            // A copy as an array of dictionaries just to extract "sys.type" field.
            guard let jsonItems = try container.decodeIfPresent(Swift.Array<Any>.self, forKey: .entries) as? [[String: Any]] else {
                self.entries = nil
                return
            }
            var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .entries)
            var entries: [EntryDecodable] = []

            while entriesJSONContainer.isAtEnd == false {
                guard let sys = jsonItems[entriesJSONContainer.currentIndex]["sys"] as? [String: Any],
                    let contentTypeInfo = sys["contentType"] as? Link else {
                        let errorMessage = "SDK was unable to parse sys.type property necessary to finish resource serialization."
                        throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
                }

                let contentTypes = decoder.userInfo[contentTypesContextKey] as! [ContentTypeId: EntryDecodable.Type]
                // TODO: Throw error instead of force unwrapping?
                let type = contentTypes[contentTypeInfo.id]!
                let entryModellable = try type.makeFrom(container: &entriesJSONContainer)
                entries.append(entryModellable)
            }
            self.entries = entries

            for entry in entries {
                linkResolver.dataCache.add(entry: entry)
            }
        }
    }
}

extension MixedDecodedEntriesArrayResponse: Decodable {

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        skip            = try container.decode(UInt.self, forKey: .skip)
        total           = try container.decode(UInt.self, forKey: .total)
        limit           = try container.decode(UInt.self, forKey: .limit)

        // All items and includes.
        includes        = try container.decodeIfPresent(MixedDecodedEntriesArrayResponse.Includes.self, forKey: .includes)

        // A copy as an array of dictionaries just to extract "sys.type" field.
        guard let jsonItems = try container.decode(Swift.Array<Any>.self, forKey: .items) as? [[String: Any]] else {
            throw SDKError.unparseableJSON(data: nil, errorMessage: "SDK was unable to serialize returned resources")
        }
        var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .items)
        var entries: [EntryDecodable] = []

        while entriesJSONContainer.isAtEnd == false {
            guard let sys = jsonItems[entriesJSONContainer.currentIndex]["sys"] as? [String: Any],
                let contentTypeInfo = sys["contentType"] as? Link else {

                    let errorMessage = "SDK was unable to parse sys.type property necessary to finish resource serialization."
                    throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
            }

            let contentTypes = decoder.userInfo[contentTypesContextKey] as! [ContentTypeId: EntryDecodable.Type]
            // TODO: Throw error instead of force unwrapping?
            let type = contentTypes[contentTypeInfo.id]!
            let entryModellable = try type.makeFrom(container: &entriesJSONContainer)
            entries.append(entryModellable)
        }
        self.items = entries

        let linkResolver = decoder.userInfo[linkResolverContext] as! LinkResolver
        for entry in entries {
            linkResolver.dataCache.add(entry: entry)
        }
        decoder.linkResolver.churnLinks()
    }
    private enum CodingKeys: String, CodingKey {
        case items, includes, skip, limit, total
    }
}





