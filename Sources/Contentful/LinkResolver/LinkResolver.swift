//
//  Contentful
//
//  Created by Tomasz Szulc on 26/09/2020.
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

import Foundation

class LinkResolver {

    private var dataCache: DataCache = DataCache()

    private var callbacks: [String: [(AnyObject) -> Void]] = [:]

    private static let linksArrayPrefix = "linksArrayPrefix"

    /// Perform data decoding in the `decoding` block. The link resolver will call completion block
    /// when all the links are resolved.
    internal func perform(decoding: @escaping () -> Void, completion: @escaping () -> Void) {
        decoding()
        churnLinks(completion: completion)
    }

    func cache(assets: [Asset]) {
        for asset in assets {
            dataCache.add(asset: asset)
        }
    }

    func cache(entryDecodables: [EntryDecodable]) {
        for entryDecodable in entryDecodables {
            dataCache.add(entry: entryDecodable)
        }
    }

    // Caches the callback to resolve the relationship represented by a Link at a later time.
    func resolve(_ link: Link, callback: @escaping (AnyObject) -> Void) {
        let key = DataCache.cacheKey(for: link)
        // Swift 4 API enables setting a default value, if none exists for the given key.
        callbacks[key, default: []] += [callback]
    }

    func resolve(_ links: [Link], callback: @escaping (AnyObject) -> Void) {
        let linksIdentifier: String = links.reduce(into: LinkResolver.linksArrayPrefix) { id, link in
            id += "," + DataCache.cacheKey(for: link)
        }
        callbacks[linksIdentifier, default: []] += [callback]
    }

    // Executes all cached callbacks to resolve links and then clears the callback cache and the data cache
    // where resources are cached before being resolved.
    private func churnLinks(completion: @escaping () -> Void) {
        for (linkKey, callbacksList) in callbacks {
            if linkKey.hasPrefix(LinkResolver.linksArrayPrefix) {
                let firstKeyIndex = linkKey.index(linkKey.startIndex, offsetBy: LinkResolver.linksArrayPrefix.count)
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

        completion()
    }
}
