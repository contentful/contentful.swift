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
    /// The url parameters relevant for the next sync operation that this `SyncSpace` can perform.
    public var parameters: [String: String] {
        if syncToken.isEmpty {
            var parameters = [String: String]()
            parameters["initial"] = true.description

            if let limit = limit {
                parameters["limit"] = limit.description
            }

            return parameters
        } else {
            return ["sync_token": syncToken]
        }
    }

    /// The entity types in Contentful that a sync can be restricted to.
    public enum SyncableTypes {
        /// Sync all assets and all entries of all content types.
        case all
        /// Sync only entities which are entries (i.e. instances of your content types(s)).
        case entries
        /// Sync only assets.
        case assets
        /// Sync only entities of a specific content type.
        case entriesOfContentType(withId: String)
        /// Sync only deleted entries or assets.
        case allDeletions
        /// Sync only deleted entries.
        case deletedEntries
        /// Sync only deleted assets.
        case deletedAssets

        /// Query parameters.
        public var parameters: [String: String] {
            let typeParameter = "type"
            switch self {
            case .all:
                // Return empty dictionary to specify that all content should be sync'ed.
                return [:]
            case .entries:
                return [typeParameter: "Entry"]
            case .assets:
                return [typeParameter: "Asset"]
            case .allDeletions:
                return [typeParameter: "Deletion"]
            case .deletedEntries:
                return [typeParameter: "DeletedEntry"]
            case .deletedAssets:
                return [typeParameter: "DeletedAsset"]
            case let .entriesOfContentType(contentTypeId):
                return [typeParameter: "Entry", QueryParameter.contentType: contentTypeId]
            }
        }
    }

    var assetsMap = [String: Asset]()
    var entriesMap = [String: Entry]()

    /// An array of identifiers for assets that were deleted after the last sync operations.
    public var deletedAssetIds = [String]()

    /// An array of identifiers for entries that were deleted after the last sync operations.
    public var deletedEntryIds = [String]()

    public internal(set) var hasMorePages: Bool

    /// A token which needs to be present to perform a subsequent synchronization operation
    public internal(set) var syncToken = ""

    /// Number of entities per page in a sync operation. See documentation for details.
    public internal(set) var limit: Int?

    /// List of Assets currently published on the Space being synchronized
    public var assets: [Asset] {
        return Array(assetsMap.values)
    }

    /// List of Entries currently published on the Space being synchronized
    public var entries: [Entry] {
        return Array(entriesMap.values)
    }

    /// The sync token from a previous synchronization
    ///
    /// - Parameter syncToken: The sync token from a previous synchronization.
    public init(syncToken: String = "", limit: Int? = nil) {
        hasMorePages = false
        self.syncToken = syncToken
        self.limit = limit
    }

    static func syncToken(from urlString: String) -> String {
        guard let components = URLComponents(string: urlString)?.queryItems else { return "" }
        for component in components {
            if let value = component.value, component.name == "sync_token" {
                return value
            }
        }
        return ""
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var syncUrl = try container.decodeIfPresent(String.self, forKey: .nextPageUrl)
        var hasMorePages = true

        if syncUrl == nil {
            hasMorePages = false
            syncUrl = try container.decodeIfPresent(String.self, forKey: .nextSyncUrl)
        }

        guard let nextSyncUrl = syncUrl else {
            throw SDKError.unparseableJSON(data: nil, errorMessage: "No sync url for future sync operations was serialized from the response.")
        }

        syncToken = SyncSpace.syncToken(from: nextSyncUrl)
        self.hasMorePages = hasMorePages

        var itemsArrayContainer = try container.nestedUnkeyedContainer(forKey: .items)
        var resources = [Resource]()

        // Decode items directly, avoiding intermediate Any or [String: Any] representations
        while !itemsArrayContainer.isAtEnd {
            let itemDecoder = try itemsArrayContainer.superDecoder()
            let sysContainer = try itemDecoder.container(keyedBy: SysContainerKeys.self).nestedContainer(keyedBy: SysKeys.self, forKey: .sys)
            let type = try sysContainer.decode(String.self, forKey: .type)

            switch type {
            case "Asset":
                let item = try Asset(from: itemDecoder)
                resources.append(item)
            case "Entry":
                let item = try Entry(from: itemDecoder)
                resources.append(item)
            case "DeletedAsset":
                let item = try DeletedResource(from: itemDecoder)
                resources.append(item)
            case "DeletedEntry":
                let item = try DeletedResource(from: itemDecoder)
                resources.append(item)
            default:
                fatalError("Unsupported resource type '\(type)'")
            }
        }

        cache(resources: resources)
    }

    private enum SysContainerKeys: String, CodingKey {
        case sys
    }

    private enum SysKeys: String, CodingKey {
        case type
    }

    private enum CodingKeys: String, CodingKey {
        case nextSyncUrl
        case nextPageUrl
        case items
    }

    func updateWithDiffs(from syncSpace: SyncSpace) {
        // Resolve all entries in-memory.
        for entry in entries {
            entry.resolveLinks(against: entriesMap, and: assetsMap)
        }

        for asset in syncSpace.assets {
            assetsMap[asset.sys.id] = asset
        }

        // Update and deduplicate all entries.
        for entry in syncSpace.entries {
            entriesMap[entry.sys.id] = entry
        }

        for deletedAssetId in syncSpace.deletedAssetIds {
            assetsMap.removeValue(forKey: deletedAssetId)
            deletedAssetIds.append(deletedAssetId)
        }

        for deletedEntryId in syncSpace.deletedEntryIds {
            entriesMap.removeValue(forKey: deletedEntryId)
            deletedEntryIds.append(deletedEntryId)
        }

        syncToken = syncSpace.syncToken
        hasMorePages = syncSpace.hasMorePages
    }

    func cache(resources: [Resource]) {
        for resource in resources {
            switch resource {
            case let asset as Asset:
                assetsMap[asset.sys.id] = asset

            case let entry as Entry:
                entriesMap[entry.sys.id] = entry

            case let deletedResource as DeletedResource:
                switch deletedResource.sys.type {
                case "DeletedAsset": deletedAssetIds.append(deletedResource.sys.id)
                case "DeletedEntry": deletedEntryIds.append(deletedResource.sys.id)
                default: break
                }

            default: break
            }
        }
    }
}
