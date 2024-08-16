//
//  DataCache.swift
//  Contentful
//
//  Created by JP Wright on 31.07.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

class DataCache {
    private static let cacheKeyDelimiter = "_"

    static func cacheKey(for link: Link) -> String {
        let linkType: String
        switch link {
        case .asset: linkType = "asset"
        case .entry, .entryDecodable: linkType = "entry"
        case let .unresolved(sys): linkType = sys.linkType
        }

        let cacheKey = DataCache.cacheKey(id: link.id, linkType: linkType)
        return cacheKey
    }

    private static func cacheKey(id: String, linkType: String) -> String {
        let delimeter = DataCache.cacheKeyDelimiter
        let cacheKey = id + delimeter + linkType.lowercased() + delimeter
        return cacheKey
    }

    private var assetCache = [String: Asset]()
    private var entryCache = [String: Any]()

    func add(asset: Asset) {
        assetCache[DataCache.cacheKey(id: asset.id, linkType: "Asset")] = asset
    }

    func add(entry: EntryDecodable) {
        entryCache[DataCache.cacheKey(id: entry.id, linkType: "Entry")] = entry
    }

    func asset(for identifier: String) -> Asset? {
        return assetCache[identifier]
    }

    func entry(for identifier: String) -> EntryDecodable? {
        return entryCache[identifier] as? EntryDecodable
    }

    func item<T>(for identifier: String) -> T? {
        return item(for: identifier) as? T
    }

    func item(for identifier: String) -> Any? {
        var target: Any? = asset(for: identifier)

        if target == nil {
            target = entry(for: identifier)
        }

        return target
    }
}
