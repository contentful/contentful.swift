//
//  SyncSpace.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation

/// A container for the synchronized state of a Space
public final class SyncSpace: Decodable {
    internal var assetsMap = [String: Asset]()
    internal var entriesMap = [String: Entry]()

    public var deletedAssetIds = [String]()
    public var deletedEntryIds = [String]()

    internal var hasMorePages: Bool

    /// A token which needs to be present to perform a subsequent synchronization operation
    internal(set) public var syncToken = ""

    /// List of Assets currently published on the Space being synchronized
    public var assets: [Asset] {
        return Array(assetsMap.values)
    }

    /// List of Entries currently published on the Space being synchronized
    public var entries: [Entry] {
        return Array(entriesMap.values)
    }

    /**
     Continue a synchronization with previous data.

     - parameter syncToken: The sync token from a previous synchronization

     - returns: An initialized synchronized space instance
     **/
    public init(syncToken: String) {
        self.hasMorePages = false
        self.syncToken = syncToken
    }

    internal static func syncToken(from urlString: String) -> String {
        guard let components = URLComponents(string: urlString)?.queryItems else { return "" }
        for component in components {
            if let value = component.value, component.name == "sync_token" {
                return value
            }
        }
        return ""
    }

    public required init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        var syncUrl     = try container.decodeIfPresent(String.self, forKey: .nextPageUrl)

        var hasMorePages = true
        if syncUrl == nil {
            hasMorePages = false
            syncUrl     = try container.decodeIfPresent(String.self, forKey: .nextSyncUrl)
        }

        guard let nextSyncUrl = syncUrl else {
            // TODO: Error message.
            fatalError("TODO")
        }
        self.syncToken = SyncSpace.syncToken(from: nextSyncUrl)
        self.hasMorePages = hasMorePages

        // A copy as an array of dictionaries just to extract "sys.type" field.
        // FIXME: throw error
        guard let items = try container.decode(Array<Any>.self, forKey: .items) as? [[String: Any]] else {
            // TODO: correct error TypeMismath
            throw SDKError.invalidClient()
        }
        var itemsArrayContainer = try container.nestedUnkeyedContainer(forKey: .items)

        var resources = [Resource]()
        while itemsArrayContainer.isAtEnd == false {

            guard let sys = items[itemsArrayContainer.currentIndex]["sys"] as? [String: Any], let type = sys["type"] as? String else {
                // TODO: correct error
                throw SDKError.invalidClient()
            }
            let item: Resource
            switch type {
            case "Asset":           item = try itemsArrayContainer.decode(Asset.self)
            case "Entry":           item = try itemsArrayContainer.decode(Entry.self)
                // FIXME: 
//            case "ContentType":     item = try itemsArrayContainer.decode(ContentType.self)
            case "DeletedAsset":    item = try itemsArrayContainer.decode(DeletedResource.self)
            case "DeletedEntry":    item = try itemsArrayContainer.decode(DeletedResource.self)
            default: fatalError("Unsupported resource type '\(type)'")
            }
            resources.append(item)
        }

        cache(resources: resources)
    }

    private enum CodingKeys: String, CodingKey {
        case nextSyncUrl
        case nextPageUrl
        case items
    }

    internal func updateWithDiffs(from syncSpace: SyncSpace) {

        for asset in syncSpace.assets {
            assetsMap[asset.sys.id] = asset
        }

        // Update and deduplicate all entries.
        for entry in syncSpace.entries {
            entriesMap[entry.sys.id] = entry
        }

        // Resolve all entries in-memory.
        for entry in entries {
            entry.resolveLinks(against: entries, and: assets)
        }

        for deletedAssetId in syncSpace.deletedAssetIds {
            assetsMap.removeValue(forKey: deletedAssetId)
        }

        for deletedEntryId in syncSpace.deletedEntryIds {
            entriesMap.removeValue(forKey: deletedEntryId)
        }

        syncToken = syncSpace.syncToken
    }

    internal func cache(resources: [Resource]) {
        for resource in resources {
            switch resource {
            case let asset as Asset:
                self.assetsMap[asset.sys.id] = asset

            case let entry as Entry:
                self.entriesMap[entry.sys.id] = entry

            case let deletedResource as DeletedResource:
                switch deletedResource.sys.type {
                case "DeletedAsset": self.deletedAssetIds.append(deletedResource.sys.id)
                case "DeletedEntry": self.deletedEntryIds.append(deletedResource.sys.id)
                default: break
                }
            default: break
            }
        }
    }
}
