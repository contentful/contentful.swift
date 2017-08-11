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
     Updates the PersistenceIntegration with information about the locales supported in the current space.
     */
    func update(localeCodes: [LocaleCode])

    /**
     Update the local datastore with the latest delta messages from the most recently fetched SyncSpace response.
     
     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.
     */
    func update(with syncSpace: SyncSpace)


    /**
     This is called whenever a new Asset was created or an existing one was updated.

     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.

     - parameter asset: The created/updated Asset
     */
    func create(asset: Asset)

    /**
     This is called whenever an Asset was deleted.

     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.

     - parameter assetId: Identifier of the Asset that was deleted.
     */
    func delete(assetWithId: String)

    /**
     This is called whenever a new Entry was created or an existing one was updated.

     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.

     - parameter entry: The created/updated Entry
     */
    func create(entry: Entry)

    /**
     This is called whenever an Entry was deleted.

     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.

     - parameter entryId: Identifier of the Entry that was deleted.
     */
    func delete(entryWithId: String)

    /**
     This method is called on completion of a successful `Client.initialSync` and `Client.nextSync`
     calls so that the sync token can be cached and future launches of your application can synchronize
     without doing an `initialSync`.
     
     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.
     */
    func update(syncToken: String)

    /**
     This method is called after all `Entry`s have been created and all links have been resolved.
     The implementation should map `Entry` fields that are `Link`s to persistent relationships in
     the underlying persistent data store.

     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.
     */
    func resolveRelationships()

    /**
     This method is called after all `Asset`s and `Entry`s have been tranformed to persistable data
     structures. The implementation should actually perform the save operation to the persisent database.
     
     There is no guarantee which thread this will be called from, so it is your responsibility when implementing
     this method, to execute on whatever thread your local datastore may require operations to be executed on.
     */
    func save()
}
