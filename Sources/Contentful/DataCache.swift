//
//  DataCache.swift
//  Contentful
//
//  Created by JP Wright on 31.07.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

internal class DataCache {

    static let cacheKeyDelimiter = "_"

    internal static func cacheKey(for resource: Resource) -> String {
        let cacheKey = DataCache.cacheKey(id: resource.sys.id, linkType: resource.sys.type)
        return cacheKey
    }

    internal static func cacheKey(for link: Link) -> String {
        let linkType: String
        switch link {
        case .asset:                linkType = "asset"
        case .entry:                linkType = "entry"
        case .unresolved(let sys):  linkType = sys.linkType
        }

        let cacheKey = DataCache.cacheKey(id: link.id, linkType: linkType)
        return cacheKey
    }

    internal static func cacheKey(for arrayResponseError: ArrayResponseError) -> String {
        let resourceId = arrayResponseError.details.id
        let linkType = arrayResponseError.details.linkType
        let cacheKey = DataCache.cacheKey(id: resourceId, linkType: linkType)
        return cacheKey
    }

    private static func cacheKey(id: String, linkType: String) -> String {
        let delimeter = DataCache.cacheKeyDelimiter
        let cacheKey = id + delimeter + linkType.lowercased() + delimeter
        return cacheKey
    }

    var assetCache = Dictionary<String, Asset>()
    var entryCache = Dictionary<String, Any>()
    var unresolvableLinksErrorCache = Dictionary<String, ArrayResponseError>()

    internal func add(asset: Asset) {
        assetCache[DataCache.cacheKey(for: asset)] = asset
    }

    internal func add(entry: EntryDecodable) {
        entryCache[DataCache.cacheKey(for: entry)] = entry
    }

    internal func asset(for identifier: String) -> Asset? {
        return assetCache[identifier]
    }

    internal func entry(for identifier: String) -> EntryDecodable? {
        return entryCache[identifier] as? EntryDecodable
    }

    internal func unresolvableLink(for identifier: String) -> ArrayResponseError? {
        return unresolvableLinksErrorCache[identifier]
    }

    internal func item<T>(for identifier: String) -> T? {
        return item(for: identifier) as? T
    }

    internal func item(for identifier: String) -> Any? {
        var target: Any? = self.asset(for: identifier)

        if target == nil {
            target = self.entry(for: identifier)
        }
        if target == nil {
            target = self.unresolvableLink(for: identifier)
        }
        return target
    }

    internal func cache(unresolvableLink: ArrayResponseError) {
        unresolvableLinksErrorCache[DataCache.cacheKey(for: unresolvableLink)] = unresolvableLink
    }
}
