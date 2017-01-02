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
public final class SyncSpace {
    fileprivate var assetsMap = [String:Asset]()
    fileprivate var entriesMap = [String:Entry]()

    var deletedAssets = [String]()
    var deletedEntries = [String]()

    var delegate: SyncSpaceDelegate?
    let nextPage: Bool
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

    var client: Client? = nil

    internal init(nextPage: Bool, nextUrl: String, items: [Resource]) {
        self.nextPage = nextPage

        URLComponents(string: nextUrl)?.queryItems?.forEach {
            if let value = $0.value, $0.name == "sync_token" {
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
        self.nextPage = false
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
    @discardableResult public func sync(matching: [String : Any] = [:], completion: @escaping (Result<SyncSpace>) -> Void) -> URLSessionDataTask? {
        guard let client = self.client else {
            completion(.error(SDKError.invalidClient()))
            return nil
        }

        var parameters = matching
        parameters["sync_token"] = syncToken as AnyObject?
        let (task, signal) = client.sync(matching: parameters)

        signal.then { space in
            space.assets.forEach {
                self.delegate?.create(asset: $0)
                self.assetsMap[$0.identifier] = $0
            }

            space.entries.forEach {
                self.delegate?.create(entry: $0)
                self.entriesMap[$0.identifier] = $0
            }

            space.deletedAssets.forEach {
                self.delegate?.delete(assetWithId: $0)
                self.assetsMap.removeValue(forKey: $0)
            }

            space.deletedEntries.forEach {
                self.delegate?.delete(entryWithId: $0)
                self.entriesMap.removeValue(forKey: $0)
            }

            self.syncToken = space.syncToken

            completion(.success(self))
        }.error {
            completion(.error($0))
        }

        return task
    }

    /**
     Perform a subsequent synchronization operation, updating this object with the latest content from
     Contentful.

     Calling this will mutate the instance and also return a reference to itself to the completion
     handler in order to allow chaining of operations.

     - parameter matching: Additional options for the synchronization

     - returns: A tuple of data task and a signal which fires on completion
     **/
    public func sync(matching: [String : Any] = [:]) -> (URLSessionDataTask?, Observable<Result<SyncSpace>>) {
        let closure: SignalObservation<[String : Any], SyncSpace> = sync(matching:completion:)
        return signalify(parameter: matching, closure: closure)
    }
}
