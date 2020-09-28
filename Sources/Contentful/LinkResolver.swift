//
//  Contentful
//
//  Created by Tomasz Szulc on 26/09/2020.
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

import Foundation

internal class LinkResolver {

    private enum Constant {
        static let linksArrayPrefix = "linksArrayPrefix"
    }

    private var dataCache = DataCache()
    private var callbacks: [String: [(AnyObject) -> Void]] = [:]

    internal func cache(assets: [Asset]) {
        assets.forEach { dataCache.add(asset: $0) }
    }

    internal func cache(entryDecodables: [EntryDecodable]) {
        entryDecodables.forEach { dataCache.add(entry: $0) }
    }

    // Caches the callback to resolve the relationship represented by a Link at a later time.
    internal func resolve(_ link: Link, callback: @escaping (AnyObject) -> Void) {
        let key = DataCache.cacheKey(for: link)
        // Swift 4 API enables setting a default value, if none exists for the given key.
        callbacks[key, default: []] += [callback]
    }

    internal func resolve(_ links: [Link], callback: @escaping (AnyObject) -> Void) {
        let linksIdentifier: String = links.reduce(into: Constant.linksArrayPrefix) { id, link in
            id += "," + DataCache.cacheKey(for: link)
        }
        callbacks[linksIdentifier, default: []] += [callback]
    }

    // Executes all cached callbacks to resolve links and then clears the callback cache and the data cache
    // where resources are cached before being resolved.
    internal func churnLinks() {
        for (linkKey, callbacksList) in callbacks {
            if linkKey.hasPrefix(Constant.linksArrayPrefix) {
                let firstKeyIndex = linkKey.index(linkKey.startIndex, offsetBy: Constant.linksArrayPrefix.count)
                let onlyKeysString = linkKey[firstKeyIndex ..< linkKey.endIndex]
                // Split creates a [Substring] array, but we need [String] to index the cache
                let keys = onlyKeysString.split(separator: ",").map { String($0) }
                let items: [AnyObject] = keys.compactMap { dataCache.item(for: $0) }
                for callback in callbacksList {
                    callback(items as AnyObject)
                }
                callbacks[linkKey] = nil
            } else {
                let item = dataCache.item(for: linkKey)
                for callback in callbacksList {
                    callback(item as AnyObject)
                }
                callbacks[linkKey] = nil
            }
        }

        if callbacks.isEmpty == true {
            self.dataCache = DataCache()
        }
    }
}
