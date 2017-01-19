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

    internal init(hasMorePages: Bool, nextUrl: String, items: [Resource]) {
        self.hasMorePages = hasMorePages

        NSURLComponents(string: nextUrl)?.queryItems?.forEach {
            if let value = $0.value where $0.name == "sync_token" {
                self.syncToken = value
            }
        }

        items.forEach {
            if let asset = $0 as? Asset {
                self.assetsMap[asset.identifier] = asset
            }

            if let entry = $0 as? Entry {
                self.entriesMap[entry.identifier] = entry
            }

            if let deleted = $0 as? DeletedResource {
                switch deleted.type {
                case "DeletedAsset": self.deletedAssets.append(deleted.identifier)
                case "DeletedEntry": self.deletedEntries.append(deleted.identifier)
                default: break
                }
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
                syncSpace.assets.forEach {
                    self.delegate?.createAsset($0)
                    self.assetsMap[$0.identifier] = $0
                }

                syncSpace.entries.forEach {
                    self.delegate?.createEntry($0)
                    self.entriesMap[$0.identifier] = $0
                }

                syncSpace.deletedAssets.forEach {
                    self.delegate?.deleteAsset($0)
                    self.assetsMap.removeValueForKey($0)
                }

                syncSpace.deletedEntries.forEach {
                    self.delegate?.deleteEntry($0)
                    self.entriesMap.removeValueForKey($0)
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
