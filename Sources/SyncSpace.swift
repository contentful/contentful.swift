//
//  SyncSpace.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar
import ObjectMapper

/// Delegate protocol for receiving updates performed during synchronization
public protocol SyncSpaceDelegate {
    /**
     This is called whenever a new Asset was created or an existing one was updated.

     - parameter asset: The created/updated Asset
     */
    func create(asset: Asset)

    /**
     This is called whenever an Asset was deleted.

     - parameter assetId: Identifier of the Asset that was deleted.
     */
    func delete(assetWithId: String)

    /**
     This is called whenever a new Entry was created or an existing one was updated.

     - parameter entry: The created/updated Entry
     */
    func create(entry: Entry)

    /**
     This is called whenever an Entry was deleted.

     - parameter entryId: Identifier of the Entry that was deleted.
     */
    func delete(entryWithId: String)
}

/// A container for the synchronized state of a Space
public final class SyncSpace: ImmutableMappable {
    fileprivate var assetsMap = [String: Asset]()
    fileprivate var entriesMap = [String: Entry]()

    var deletedAssets = [String]()
    var deletedEntries = [String]()

    var delegate: SyncSpaceDelegate?

    var hasMorePages: Bool!

    /// A token which needs to be present to perform a subsequent synchronization operation
    fileprivate(set) public var syncToken = ""

    /// List of Assets currently published on the Space being synchronized
    public var assets: [Asset] {
        return Swift.Array(assetsMap.values)
    }

    /// List of Entries currently published on the Space being synchronized
    public var entries: [Entry] {
        return Swift.Array(entriesMap.values)
    }

    var client: Client?

    /**
     Continue a synchronization with previous data.

     - parameter client:    The client to use for synchronization
     - parameter syncToken: The sync token from a previous synchronization
     - parameter delegate:  A delegate for receiving updates to your data store

     - returns: An initialized synchronized space instance
     **/
    public init(client: Client, syncToken: String, delegate: SyncSpaceDelegate) {
        self.client = client
        self.delegate = delegate
        self.hasMorePages = false
        self.syncToken = syncToken
    }

    /**
     Perform a subsequent synchronization operation, updating this object with the 
     latest content from Contentful.
     
     Calling this will mutate the instance and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - parameter matching:   Additional options for the synchronization
     - parameter completion: A handler which will be called on completion of the operation

     - returns: The data task being used, enables cancellation of requests
     **/
    @discardableResult public func sync(matching: [String: Any] = [:], completion: @escaping (Result<SyncSpace>) -> Void) -> URLSessionDataTask? {
        guard let client = self.client else {
            completion(.error(SDKError.invalidClient()))
            return nil
        }

        // Callback to merge the most recent sync page with the current sync space.
        let syncCompletion: (Result<SyncSpace>) -> Void = { result in

            switch result {
            case .success(let syncSpace):

                for asset in syncSpace.assets {
                    self.delegate?.create(asset: asset)
                    self.assetsMap[asset.sys.id] = asset
                }

                for entry in syncSpace.entries {
                    entry.resolveLinks(against: self.entries + syncSpace.entries, and: self.assets)
                    self.delegate?.create(entry: entry)
                    self.entriesMap[entry.sys.id] = entry
                }

                for deletedAssetId in syncSpace.deletedAssets {
                    self.delegate?.delete(assetWithId: deletedAssetId)
                    self.assetsMap.removeValue(forKey: deletedAssetId)
                }

                for deletedEntryId in syncSpace.deletedEntries {
                    self.delegate?.delete(entryWithId: deletedEntryId)
                    self.entriesMap.removeValue(forKey: deletedEntryId)
                }

                self.syncToken = syncSpace.syncToken

                completion(.success(self))
            case .error(let error):
                completion(.error(error))
            }
        }

        var parameters = matching
        parameters["sync_token"] = syncToken

        let task = client.sync(matching: parameters, completion: syncCompletion)
        return task
    }

    /**
     Perform a subsequent synchronization operation, updating this object with 
     the latest content from Contentful.

     Calling this will mutate the instance and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - parameter matching: Additional options for the synchronization

     - returns: A tuple of data task and a signal which fires on completion
     **/
    public func sync(matching: [String: Any] = [:]) -> Observable<Result<SyncSpace>> {
        let asyncDataTask: AsyncDataTask<[String: Any], SyncSpace> = sync(matching:completion:)
        return toObservable(parameter: matching, asyncDataTask: asyncDataTask).observable
    }

    func syncToken(from urlString: String) -> String {
        guard let components = URLComponents(string: urlString)?.queryItems else { return "" }
        for component in components {
            if let value = component.value, component.name == "sync_token" {
                return value
            }
        }
        return ""
    }


    // MARK: <ImmutableMappable>

    public required init(map: Map) throws {
        var hasMorePages = true
        var syncUrl: String?
        syncUrl <- map["nextPageUrl"]

        if syncUrl == nil {
            hasMorePages = false
            syncUrl <- map["nextSyncUrl"]
        }

        self.hasMorePages = hasMorePages
        self.syncToken = self.syncToken(from: syncUrl!)

        var items: [[String: Any]]!
        items <- map["items"]

        let resources: [Resource] = items.flatMap { itemJSON in
            let map = Map(mappingType: .fromJSON, JSON: itemJSON, context: map.context)

            var type: String!
            type <- map["sys.type"]
            switch type {
            case "Asset":           return try? Asset(map: map)
            case "Entry":           return try? Entry(map: map)
            case "ContentType":     return try? ContentType(map: map)
            case "DeletedAsset":    return try? DeletedResource(map: map)
            case "DeletedEntry":    return try? DeletedResource(map: map)
            default: fatalError("Unsupported resource type '\(type)'")
            }

            return nil
        }

        cache(resources: resources)

        // If it's a one page sync, resolve links.
        // Otherwise, we will wait until all pages have come in to resolve them.
        if hasMorePages == false {
            for entry in entries {
                entry.resolveLinks(against: entries, and: assets)
            }
        }
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
                case "DeletedAsset": self.deletedAssets.append(deletedResource.sys.id)
                case "DeletedEntry": self.deletedEntries.append(deletedResource.sys.id)
                default: break
                }
            default: break
            }
        }
    }
}
