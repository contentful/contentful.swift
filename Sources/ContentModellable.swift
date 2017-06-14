//
//  ContentModellable.swift
//  Contentful
//
//  Created by JP Wright on 15/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public typealias ContentModelTypes = [ContentModellable.Type]

public protocol SpaceModellable: class {

}


public protocol ContentModellable: class {

    // FIXME: Assets shouldn't need fields anymore.
    init?(sys: Sys, fields: [String: Any], linkDepth: Int)
}

public protocol EntryModellable: ContentModellable {
    static var contentTypeId: String { get }
}


public protocol PersistenceDelegate {
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


public class ContentModel {
    let spaceType: SpaceModellable.Type
    let assetType: ContentModellable.Type
    let entryTypes: [EntryModellable.Type]

    init(spaceType: SpaceModellable.Type, assetType: ContentModellable.Type, entryTypes: [EntryModellable.Type]) {
        self.spaceType = spaceType
        self.assetType = assetType
        self.entryTypes = entryTypes
    }
}


// FIXME:
public typealias ContentTypeID = String

public struct MappedContent {

    public let assets: [ContentModellable]

    public let entries: [ContentTypeID: [EntryModellable]]
}

internal extension ArrayResponse where ItemType: Entry {

    // FIXME: LinkDepth!



    internal func toMappedContent(for contentModel: ContentModel?) -> MappedContent {

        // Annoying workaround for type system not allowing cast of items to [Entry]
        let entries: [Entry] = items.flatMap { $0 as Entry }

        let allEntries = entries + (includedEntries ?? [])

        var mappedEntriesDictionary = [ContentTypeID: [EntryModellable]]()

        // FIXME:
        let entryTypes = contentModel!.entryTypes

        for entryType in entryTypes {
            let entriesForContentType = allEntries.filter { $0.sys.contentTypeId == entryType.contentTypeId }
            // Map to user-defined types
            let mappedEntriesForContentType: [EntryModellable] = entriesForContentType.flatMap { entryType.init(sys: $0.sys, fields: $0.fields, linkDepth: 20) }
            mappedEntriesDictionary[entryType.contentTypeId] = mappedEntriesForContentType
        }

        // assets
        let allAssets = includedAssets ?? []
        let mappedAssets = allAssets.flatMap { contentModel!.assetType.init(sys: $0.sys, fields: $0.fields, linkDepth: 20) }

        let mappedContent = MappedContent(assets: mappedAssets, entries: mappedEntriesDictionary)
        return mappedContent
    }
}
