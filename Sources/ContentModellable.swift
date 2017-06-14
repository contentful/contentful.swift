//
//  ContentModellable.swift
//  Contentful
//
//  Created by JP Wright on 15/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public typealias ContentTypeId = String

public protocol ContentModellable: class {
    var id: String { get }
}

public protocol SpaceModellable: ContentModellable {
    /// The current synchronization token
    var syncToken: String? { get set }
}
//
//public protocol AssetModellable: ContentModellable {
//    /// URL of the Asset
//    var urlString: String? { get set }
//
//    init?(asset: Asset)
//}

public protocol EntryModellable: ContentModellable {
    static var contentTypeId: ContentTypeId { get }

    init?(entry: Entry, linkDepth: Int)
}

public class ContentModel {
    let spaceType: SpaceModellable.Type
//    let assetType: AssetModellable.Type
    let entryTypes: [EntryModellable.Type]

    init(spaceType: SpaceModellable.Type, entryTypes: [EntryModellable.Type]) {
        self.spaceType = spaceType
//        self.assetType = assetType
        self.entryTypes = entryTypes
    }
}

public struct MappedContent {

    public let assets: [Asset]

    public let entries: [ContentTypeId: [EntryModellable]]
}

internal extension ArrayResponse where ItemType: Entry {

    internal func toMappedContent(for contentModel: ContentModel?) -> MappedContent {

        // Annoying workaround for type system not allowing cast of items to [Entry]
        let entries: [Entry] = items.flatMap { $0 as Entry }

        let allEntries = entries + (includedEntries ?? [])

        var mappedEntriesDictionary = [ContentTypeId: [EntryModellable]]()

        let entryTypes = contentModel?.entryTypes ?? []

        for entryType in entryTypes {
            let entriesForContentType = allEntries.filter { $0.sys.contentTypeId == entryType.contentTypeId }
            // Map to user-defined types
            let mappedEntriesForContentType: [EntryModellable] = entriesForContentType.flatMap { entryType.init(entry: $0, linkDepth: 20) }
            mappedEntriesDictionary[entryType.contentTypeId] = mappedEntriesForContentType
        }

        // assets
        let allAssets = includedAssets ?? []

        let mappedContent = MappedContent(assets: allAssets, entries: mappedEntriesDictionary)
        return mappedContent
    }
}
