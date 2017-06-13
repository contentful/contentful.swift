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
