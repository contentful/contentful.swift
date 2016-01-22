//
//  SyncSpace.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

public final class SyncSpace {
    private var assetsMap = [String:Asset]()
    private var entriesMap = [String:Entry]()

    private var deletedAssets = [String]()
    private var deletedEntries = [String]()

    private(set) public var syncToken = ""

    public var assets: [Asset] {
        return Array(assetsMap.values)
    }

    public var entries: [Entry] {
        return Array(entriesMap.values)
    }

    internal(set) public var client: Client? = nil

    internal init(nextSyncUrl: String, items: [Resource]) {
        NSURLComponents(string: nextSyncUrl)?.queryItems?.forEach {
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
                case "Asset": self.deletedAssets.append(deleted.identifier)
                case "Entry": self.deletedEntries.append(deleted.identifier)
                default: break
                }
            }
        }
    }

    public func sync(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<SyncSpace> -> Void) -> NSURLSessionDataTask? {
        guard let client = self.client else {
            completion(.Error(ContentfulError.InvalidClient()))
            return nil
        }

        var parameters = matching
        parameters["sync_token"] = syncToken
        let (task, signal) = client.sync(parameters)

        signal.next { space in
            space.assets.forEach { self.assetsMap[$0.identifier] = $0 }
            space.entries.forEach { self.entriesMap[$0.identifier] = $0 }

            space.deletedAssets.forEach { self.assetsMap.removeValueForKey($0) }
            space.deletedEntries.forEach { self.entriesMap.removeValueForKey($0) }

            self.syncToken = space.syncToken

            completion(.Success(self))
        }.error {
            completion(.Error($0))
        }

        return task
    }
}
