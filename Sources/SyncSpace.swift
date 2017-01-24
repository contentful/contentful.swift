//
//  SyncSpace.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

/// Delegate protocol for receiving updates performed during synchronization
public protocol SyncSpaceDelegate {
    /**
     This is called whenever a new Asset was created or an existing one was updated.

     - parameter asset: The created/updated Asset
     */
    func createAsset(asset: Asset)

    /**
     This is called whenever an Asset was deleted.

     - parameter assetId: Identifier of the Asset that was deleted.
     */
    func deleteAsset(assetId: String)

    /**
     This is called whenever a new Entry was created or an existing one was updated.

     - parameter entry: The created/updated Entry
     */
    func createEntry(entry: Entry)

    /**
     This is called whenever an Entry was deleted.

     - parameter entryId: Identifier of the Entry that was deleted.
     */
    func deleteEntry(entryId: String)
}

/// A container for the synchronized state of a Space
public final class SyncSpace {
    private var assetsMap = [String:Asset]()
    private var entriesMap = [String:Entry]()

    // Used for resolving links.
    private var includes = [String:Resource]()

    var deletedAssets = [String]()
    var deletedEntries = [String]()

    var delegate: SyncSpaceDelegate?
    public let hasMorePages: Bool
    /// A token which needs to be present to perform a subsequent synchronization operation
    private(set) public var syncToken = ""

    /// List of Assets currently published on the Space being synchronized
    public var assets: [Asset] {
        return Swift.Array(assetsMap.values)
    }

    /// List of Entries currently published on the Space being synchronized
    public var entries: [Entry] {
        return Swift.Array(entriesMap.values)
    }

    var client: Client? = nil

    internal init(hasMorePages: Bool, nextUrl: String, items: [Resource], includes: [String:Resource]) {
        self.hasMorePages = hasMorePages
        self.includes = includes

        NSURLComponents(string: nextUrl)?.queryItems?.forEach {
            if let value = $0.value where $0.name == "sync_token" {
                self.syncToken = value
            }
        }

        for item in items {
            switch item {
            case let asset as Asset:
                self.assetsMap[asset.identifier] = asset

            case let entry as Entry:
                self.entriesMap[entry.identifier] = entry

            case let deletedResource as DeletedResource:
                switch deletedResource.type {
                case "DeletedAsset": self.deletedAssets.append(deletedResource.identifier)
                case "DeletedEntry": self.deletedEntries.append(deletedResource.identifier)
                default: break
                }
            default: break
            }
        }
    }

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
     Perform a subsequent synchronization operation, updating this object with the latest content from
     Contentful. 
     
     Calling this will mutate the instance and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - parameter matching:   Additional options for the synchronization
     - parameter completion: A handler which will be called on completion of the operation

     - returns: The data task being used, enables cancellation of requests
     **/
    public func sync(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<SyncSpace> -> Void) -> NSURLSessionDataTask? {
        guard let client = self.client else {
            completion(.Error(Error.InvalidClient()))
            return nil
        }

        let syncCompletion: (Result<SyncSpace>) -> () = { result in

            switch result {
            case .Success(let syncSpace):

                // Update includes.
                self.includes = self.includes + syncSpace.includes

                for asset in syncSpace.assets {
                    self.delegate?.createAsset(asset)
                    self.assetsMap[asset.identifier] = asset
                }

                for entry in syncSpace.entries {
                    // For syncspaces, we do NOT resolve links during array decoding, but instead postpone
                    // To enabling linking with currently synced items.
                    let resolvedEntry = entry.resolveLinks(againstIncludes: self.includes)
                    self.delegate?.createEntry(resolvedEntry)
                    self.entriesMap[entry.identifier] = resolvedEntry
                }

                for deletedAsset in syncSpace.deletedAssets {
                    self.delegate?.deleteAsset(deletedAsset)
                    self.assetsMap.removeValueForKey(deletedAsset)
                }

                for deletedEntry in syncSpace.deletedEntries {
                    self.delegate?.deleteEntry(deletedEntry)
                    self.entriesMap.removeValueForKey(deletedEntry)
                }
                
                self.syncToken = syncSpace.syncToken
                
                completion(.Success(self))
            case .Error(let error):
                completion(.Error(error))
            }
        }

        var parameters = matching
        parameters["sync_token"] = syncToken

        let task = client.sync(parameters, completion: syncCompletion)
        return task
    }
}
