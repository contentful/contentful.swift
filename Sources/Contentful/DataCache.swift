//
//  DataCache.swift
//  Contentful
//
//  Created by JP Wright on 31.07.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation


/// Implemented using `NSCache`
internal class DataCache {

    static let cacheKeyDelimiter = "_"

    internal static func cacheKey(for resource: EntryModellable) -> String {
        let delimeter = DataCache.cacheKeyDelimiter

        let cacheKey =  resource.id + delimeter + "entry" + delimeter + resource.localeCode
        return cacheKey
    }

    internal static func cacheKey(for resource: LocalizableResource) -> String {
        let delimeter = DataCache.cacheKeyDelimiter

        // Look at the type info.
        let cacheKey =  resource.id + delimeter + resource.sys.type.lowercased() + delimeter + resource.currentlySelectedLocale.code
        return cacheKey
    }

    let assetCache = NSCache<AnyObject, AnyObject>()
    let entryCache = NSCache<AnyObject, AnyObject>()

    internal func add(asset: Asset) {
        assetCache.setObject(asset, forKey: DataCache.cacheKey(for: asset) as AnyObject)
    }

    internal func add(entry: EntryModellable) {
        entryCache.setObject(entry, forKey: DataCache.cacheKey(for: entry) as AnyObject)
    }

    internal func asset(for identifier: String) -> Asset? {
        return assetCache.object(forKey: identifier as AnyObject) as? Asset
    }

    internal func entry(for identifier: String) -> EntryModellable? {
        return entryCache.object(forKey: identifier as AnyObject) as? EntryModellable
    }

    internal func item<T>(for identifier: String) -> T? {
        return item(for: identifier) as? T
    }

    internal func item(for identifier: String) -> AnyObject? {
        var target: AnyObject? = self.asset(for: identifier)

        if target == nil {
            target = self.entry(for: identifier)
        }

        return target
    }
}
