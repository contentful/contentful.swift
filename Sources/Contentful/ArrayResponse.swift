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
            assets      = try values.decodeIfPresent([Asset].self, forKey: .assets)
            entries     = try values.decodeIfPresent([Entry].self, forKey: .entries)
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

        // Workaround for type system not allowing cast of items to [Entry]
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
 A list of Contentful entries that have been mapped to types conforming to `EntryDecodable`

 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
 */
public struct MappedArrayResponse<ItemType>: HomogeneousArray where ItemType: EntryDecodable {

    /// The resources which are part of the given array
    public let items: [ItemType]

    /// The maximum number of resources originally requested
    public let limit: UInt

    /// The number of elements skipped when performing the request
    public let skip: UInt

    /// The total number of resources which matched the original request
    public let total: UInt

    internal let includes: MappedIncludes?

    internal var includedAssets: [Asset]? {
        return includes?.assets
    }
    internal var includedEntries: [EntryDecodable]? {
        return includes?.entries
    }
}

internal struct MappedIncludes: Decodable {
    let assets: [Asset]?
    let entries: [EntryDecodable]?

    private enum CodingKeys: String, CodingKey {
        case assets     = "Asset"
        case entries    = "Entry"
    }

    init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)

        assets          = try container.decodeIfPresent([Asset].self, forKey: CodingKeys.assets)
        // Cache to enable link resolution.
        if let assets = assets {
            decoder.linkResolver.cache(assets: assets)
        }

        // A copy as an array of dictionaries just to extract "sys.type" field.
        guard let jsonItems = try container.decodeIfPresent(Swift.Array<Any>.self, forKey: .entries) as? [[String: Any]] else {
            self.entries = nil
            return
        }
        var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .entries)
        var entries: [EntryDecodable] = []
        let contentTypes = decoder.userInfo[DecoderContext.contentTypesContextKey] as! [ContentTypeId: EntryDecodable.Type]

        while entriesJSONContainer.isAtEnd == false {
            let contentTypeInfo = try jsonItems.contentTypeInfo(at: entriesJSONContainer.currentIndex)

            // For includes, if the type of this entry isn't defined by the user, we skip serialization.
            if let type = contentTypes[contentTypeInfo.id] {
                let entryModellable = try type.popEntryDecodable(from: &entriesJSONContainer)
                entries.append(entryModellable)
            }
        }
        self.entries = entries

        // Cache to enable link resolution.
        if let entries = self.entries {
            decoder.linkResolver.cache(entryDecodables: entries)
        }
    }
}

extension MappedArrayResponse: Decodable {

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        skip            = try container.decode(UInt.self, forKey: .skip)
        total           = try container.decode(UInt.self, forKey: .total)
        limit           = try container.decode(UInt.self, forKey: .limit)

        // All items and includes.
        includes        = try container.decodeIfPresent(MappedIncludes.self, forKey: .includes)

        // A copy as an array of dictionaries just to extract "sys.type" field.
        guard let jsonItems = try container.decode(Swift.Array<Any>.self, forKey: .items) as? [[String: Any]] else {
            throw SDKError.unparseableJSON(data: nil, errorMessage: "SDK was unable to serialize returned resources")
        }
        var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .items)
        var entries: [EntryDecodable] = []
        let contentTypes = decoder.userInfo[DecoderContext.contentTypesContextKey] as! [ContentTypeId: EntryDecodable.Type]

        while entriesJSONContainer.isAtEnd == false {
            let contentTypeInfo = try jsonItems.contentTypeInfo(at: entriesJSONContainer.currentIndex)

            // Throw an error in this case as if there is no matching content type for the current id, then
            // we can't serialize any of the entries. The type must match ItemType as this is a homogenous array.
            guard let entryDecodableType = contentTypes[contentTypeInfo.id], entryDecodableType == ItemType.self else {
                let errorMessage = """
                A response for the QueryOn<\(ItemType.self)> did return successfully, but a serious error
                occurred when decoding the array of \(ItemType.self).
                """
                throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
            }
            let entryDecodable = try entryDecodableType.popEntryDecodable(from: &entriesJSONContainer)
            entries.append(entryDecodable)
        }

        // Workaround for type system not allowing cast of items to [ItemType].
        self.items = entries.flatMap { $0 as? ItemType }

        // Cache to enable link resolution.
        decoder.linkResolver.cache(entryDecodables: self.items)
        // Resolve links.
        decoder.linkResolver.churnLinks()
    }

    private enum CodingKeys: String, CodingKey {
        case items, includes, skip, limit, total
    }
}

/**
 A list of Contentful entries that have been mapped to types conforming to `EntryDecodable` instances.
 A MixedMappedArrayResponse respresents a heterogeneous collection of EntryDecodables being returned,
 for instance if hitting the base /entries endpoint with no additional query parameters. If there is no
 user-defined type for a particular entry, that entry will not be serialized at all. It is up to you to
 introspect the type of each element in the items array to handle the response data properly.

 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/collection-resources-and-pagination>
 */
public struct MixedMappedArrayResponse: Array {

    /// The resources which are part of the given array
    public let items: [EntryDecodable]

    /// The maximum number of resources originally requested
    public let limit: UInt

    /// The number of elements skipped when performing the request
    public let skip: UInt

    /// The total number of resources which matched the original request
    public let total: UInt

    internal let includes: MappedIncludes?

    internal var includedAssets: [Asset]? {
        return includes?.assets
    }
    internal var includedEntries: [EntryDecodable]? {
        return includes?.entries
    }
}

extension MixedMappedArrayResponse: Decodable {

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        skip            = try container.decode(UInt.self, forKey: .skip)
        total           = try container.decode(UInt.self, forKey: .total)
        limit           = try container.decode(UInt.self, forKey: .limit)

        // All items and includes.
        includes        = try container.decodeIfPresent(MappedIncludes.self, forKey: .includes)

        // A copy as an array of dictionaries just to extract "sys.type" field.
        guard let jsonItems = try container.decode(Swift.Array<Any>.self, forKey: .items) as? [[String: Any]] else {
            throw SDKError.unparseableJSON(data: nil, errorMessage: "SDK was unable to serialize returned resources")
        }
        var entriesJSONContainer = try container.nestedUnkeyedContainer(forKey: .items)
        var entries: [EntryDecodable] = []
        let contentTypes = decoder.userInfo[DecoderContext.contentTypesContextKey] as! [ContentTypeId: EntryDecodable.Type]

        while entriesJSONContainer.isAtEnd == false {
            let contentTypeInfo = try jsonItems.contentTypeInfo(at: entriesJSONContainer.currentIndex)

            // After implementing handling of the errors array, we can append an SDKError when the type isn't found.
            if let entryDecodableType = contentTypes[contentTypeInfo.id] {
                let entryDecodable = try entryDecodableType.popEntryDecodable(from: &entriesJSONContainer)
                entries.append(entryDecodable)
            }
        }
        self.items = entries

        // Cache to enable link resolution.
        decoder.linkResolver.cache(entryDecodables: self.items)
        // Resolve links.
        decoder.linkResolver.churnLinks()
    }

    private enum CodingKeys: String, CodingKey {
        case items, includes, skip, limit, total
    }
}

// Convenience method for grabbing the content type information of a json item in an array of resources.
internal extension Swift.Array where Element == Dictionary<String, Any> {

    func contentTypeInfo(at index: Int) throws -> Link {
        let errorMessage = "SDK was unable to parse sys.type property necessary to finish resource serialization."
        guard let sys = self[index]["sys"] as? [String: Any], let contentTypeInfo = sys["contentType"] as? Link else {
            throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
        }
        return contentTypeInfo
    }
}
