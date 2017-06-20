//
//  Persistence.swift
//  Contentful
//
//  Created by JP Wright on 14.06.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/**
 Conform to this protocol and initialize your `Client` instance with the `persistenceIntegration` 
 initialization parameter set to recieve messages about creation and deletion of `Entry`s and `Asset`s 
 in your space when doing sync operations using the `Client.initialSync()` and Client.nextSync()` methods.
 Proper conformance to this protocol should enable persisting the state changes that happen in your Contentful
 space to a persistent store such as `CoreData`.
 */
public protocol PersistenceIntegration: Integration {

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

    /**
     This method is called on completion of a successful `Client.initialSync` and `Client.nextSync`
     calls so that the sync token can be cached and future launches of your application can synchronize
     without doing an `initialSync`.
     */
    func update(syncToken: String)

    /**
     This method is called after all `Entry`s have been created and all links have been resolved.
     The implementation should map `Entry` fields that are `Link`s to persistent relationships in
     the underlying persistent data store.
     */
    func resolveRelationships()

    /**
     This method is called after all `Asset`s and `Entry`s have been tranformed to persistable data
     structures. The implementation should actually perform the save operation to the persisent database.
     */
    func save()
}
