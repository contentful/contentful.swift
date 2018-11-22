//
//  Persistence.swift
//  Contentful
//
//  Created by JP Wright on 14.06.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/// Conform to this protocol and initialize your `Client` instance with the `persistenceIntegration`
/// initialization parameter set to recieve messages about creation and deletion of `Entry`s and `Asset`s
/// in your space when doing sync operations using the `Client.initialSync()` and Client.nextSync()` methods.
/// Proper conformance to this protocol should enable persisting the state changes that happen in your Contentful
/// space to a persistent store such as `CoreData`.
public protocol PersistenceIntegration: Integration {

    /// Updates the `PersistenceIntegration` with information about the locales supported in the current space.
    func update(localeCodes: [LocaleCode])

    /// Updates the local datastore with the latest delta messages from the most recently fetched SyncSpace response.
    ///
    /// There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    /// this method, to execute on whatever thread your local datastore may require operations to be executed on.
    func update(with syncSpace: SyncSpace)

    /// This is called whenever a new Asset was created or an existing one was updated.
    ///
    /// There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    /// this method, to execute on whatever thread your local datastore may require operations to be executed on.
    ///
    /// - Parameter asset: he created/updated `Asset`.
    func create(asset: Asset)

    /// This is called whenever an asset was deleted.
    ///
    /// There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    /// this method, to execute on whatever thread your local datastore may require operations to be executed on.
    ///
    /// - Parameter assetId: Identifier of the asset that was deleted.
    func delete(assetWithId: String)

    /// This is called whenever a new entry was created or an existing one was updated.
    ///
    /// There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    /// this method, to execute on whatever thread your local datastore may require operations to be executed on.
    ///
    /// - Parameter entry: The created/updated `Entry`.
    func create(entry: Entry)

    /// This is called whenever an entry was deleted before the next sync.
    ///
    /// There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    /// this method, to execute on whatever thread your local datastore may require operations to be executed on.
    ///
    /// - Parameter entryId: Identifier of the entry that was deleted.
    func delete(entryWithId: String)

    /// This method is called on completion of a successful `sync` call on a `Client` instance.
    /// calls so that the sync token can be cached and future launches of your application can synchronize
    /// without doing an `sync`.
    ///
    /// There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    /// this method, to execute on whatever thread your local datastore may require operations to be executed on.
    ///
    /// - Parameter syncToken: The string sync token that should be cached to that subsequent sync's pickup at the right spot.
    func update(syncToken: String)

    ///  This method is called after all `Entry`s have been created and all links have been resolved.
    ///  The implementation should map `Entry` fields that are `Link`s to persistent relationships in
    ///  the underlying persistent data store.
    ///  There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    ///  this method, to execute on whatever thread your local datastore may require operations to be executed on.
    func resolveRelationships()

    /// This method is called after all assets and entries have been tranformed to persistable data
    /// structures. The implementation should actually perform the save operation to the persisent database.
    ///
    /// There is no guarantee which thread this will be called from, so it is your responsibility when implementing
    /// this method, to execute on whatever thread your local datastore may require operations to be executed on.
    func save()
}
