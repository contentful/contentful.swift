//
//  DataCache.swift
//  Contentful
//
//  Created by JP Wright on 31.07.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

protocol DataCacheProtocol {

    func entry(for identifier: String) -> EntryModellable?

    func item(for identifier: String) -> AnyObject?
}


/// Implemented using `NSCache`
class DataCache {

    public static func cacheKey(for resource: ContentModellable) -> String {
        // FIXME: Implicitly unwrapped optional.
        let cacheKey =  resource.id! + "_" + (resource.localeCode ?? "")
        return cacheKey
    }

    public static func cacheKey(for resource: LocalizableResource) -> String {
        let cacheKey =  resource.id + "_" + resource.currentlySelectedLocale.code
        return cacheKey
    }

    let assetCache = NSCache<AnyObject, AnyObject>()
    let entryCache = NSCache<AnyObject, AnyObject>()

    func add(entry: EntryModellable) {
        entryCache.setObject(entry, forKey: DataCache.cacheKey(for: entry) as AnyObject)
    }

    func asset(for identifier: String) -> AssetModellable? {
        return assetCache.object(forKey: identifier as AnyObject) as? AssetModellable
    }

    func entry(for identifier: String) -> EntryModellable? {
        return entryCache.object(forKey: identifier as AnyObject) as? EntryModellable
    }

    func item<T>(for identifier: String) -> T? {
        return item(for: identifier) as? T
    }

    func item(for identifier: String) -> ContentModellable? {
        var target: ContentModellable? = self.asset(for: identifier)

        if target == nil {
            target = self.entry(for: identifier)
        }

        return target
    }

    fileprivate static func cacheResource(in cache: NSCache<AnyObject, AnyObject>, resource: ContentModellable) {
        let cacheKey = DataCache.cacheKey(for: resource)
        cache.setObject(resource as AnyObject, forKey: cacheKey as AnyObject)
    }
}
