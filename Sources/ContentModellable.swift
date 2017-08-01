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

    init()

    // FIXME: Document that the system must provide a new instance.

    var id: String? { get set }

    //    /// The date representing the last time the Contentful Resource was updated.
    //    var updatedAt: Date? { get set }
    //
    //    /// The date that the Contentful Resource was first created.
    //    var createdAt: Date? { get set }

    /// The code which represents which locale the Resource of interest contains data for.
    var localeCode: String? { get set }
}

public protocol SpaceModellable: ContentModellable {
    /// The current synchronization token
    var syncToken: String? { get set }
}

public protocol EntryModellable: ContentModellable {

    /// The identifier of the Contentful content type that will map to this type of `EntryPersistable`
    static var contentTypeId: ContentTypeId { get }

    static func fieldMapping() -> [FieldName: String]

    func populateFields(from cache: [FieldName: Any])

    func populateLinks(from cache: [FieldName: Any])
}

/**
 Conform to `AssetPersistable` protocol to enable mapping of your Contentful media Assets to
 your `NSManagedObject` subclass.
 */
public protocol AssetModellable: ContentModellable {
    /// URL of the Asset.
    var urlString: String? { get set }

    /// The title of the Asset.
    var title: String? { get set }

    /// The description of the asset. Named `assetDescription` to avoid clashing with `description`
    /// property that all NSObject's have.
    var assetDescription: String? { get set }
}

public class ContentModel {
    let spaceType: SpaceModellable.Type?
    let assetType: AssetModellable.Type?
    let entryTypes: [EntryModellable.Type]

    internal let dataCache: DataCache


    init(entryTypes: [EntryModellable.Type], spaceType: SpaceModellable.Type? = nil, assetType: AssetModellable.Type? = nil) {
        self.spaceType = spaceType
        self.entryTypes = entryTypes
        self.assetType = assetType

        self.dataCache = DataCache()
        self.cachedPropertyMappingForContentTypeId = [ContentTypeId: [FieldName: String]]()
        self.cachedRelationshipMappingForContentTypeId = [ContentTypeId: [FieldName: String]]()
    }


    // Small caches for optimizing mapping.


    // Dictionary mapping source Entry id's concatenated with locale code to a dictionary with fieldName to related entry id's.
    internal var relationshipsToResolve = [String: [FieldName: Any]]()

    // Dictionary to cache mappings for fields on `Entry` to `EntryPersistable` properties for each content type.
    internal var cachedPropertyMappingForContentTypeId: [ContentTypeId: [FieldName: String]]

    internal var cachedRelationshipMappingForContentTypeId: [ContentTypeId: [FieldName: String]]


    // See if you can get the types of the class.
    internal func relationshipNames(for type: EntryModellable.Type) -> [String] {

        // Create an empty instance of the current type so that we can introspect it's properties
        // using Swift's mirror API.
        let emptyInstance = type.init()
        let mirror = Mirror(reflecting: emptyInstance)

        let relationshipNames: [String] = mirror.children.flatMap { propertyName, value in
            let type = type(of: value)

            // Filter out relationship names.
            if type is ContentModellable.Type {
                return propertyName
            } else if let optionalType = type as? OptionalProtocol.Type, optionalType.wrappedType() is ContentModellable.Type {
                return propertyName
            }
            return nil
        }

        return relationshipNames
    }

    // MARK: Relationship properties.

    // MARK: Relationship properties.

    internal func relationshipMapping(for entryType: EntryModellable.Type,
                                      and fields: [FieldName: Any]) -> [FieldName: String] {

        if let cachedRelationshipMapping = cachedRelationshipMappingForContentTypeId[entryType.contentTypeId] {
            return cachedRelationshipMapping
        }

        let mapping = entryType.fieldMapping()

        // Get just the property names.
        let relationshipPropertyNames = self.relationshipNames(for: entryType)

        let filteredMappingTuplesArray = mapping.filter { (_, propertyName) -> Bool in
            // Get intersection with what the user-defined in their fieldMapping() function
            // and the properties returned by the reflection.
            return relationshipPropertyNames.contains(propertyName) == true
        }
        let filteredMapping = Dictionary(elements: filteredMappingTuplesArray)

        // Cache.
        cachedRelationshipMappingForContentTypeId[entryType.contentTypeId] = filteredMapping
        return filteredMapping
    }

    // A type used to cache relationships that should be deleted in the `resolveRelationships()` method.
    fileprivate struct DeletedRelationship {}

    // Returns a dictionary representing the fields names and the target id(s) to create links to.
    fileprivate func cachableRelationships(for entryPersistable: EntryModellable,
                                           of type: EntryModellable.Type,
                                           with entry: Entry) -> [FieldName: Any] {

        // FieldName to either a single entry id or an array of entry id's to be linked.
        var relationships = [FieldName: Any]()

        let relationshipMapping = self.relationshipMapping(for: type, and: entry.fields)
        let relationshipFieldNames = Array(relationshipMapping.keys)

        // Get fieldNames which are links/relationships/references to other types.
        for relationshipName in relationshipFieldNames {
            guard let propertyName = relationshipMapping[relationshipName] else { continue }

            // Get the name of the property to be linked to.
            if let linkedValue = entry.fields[relationshipName] {
                if let targets = linkedValue as? [Link] {
                    // One-to-many.
                    relationships[propertyName] = targets.map { $0.id + "_" + entry.currentlySelectedLocale.code }
                } else {
                    // One-to-one.
                    assert(linkedValue is Link)
                    relationships[propertyName] = (linkedValue as! Link).id + "_" + entry.currentlySelectedLocale.code
                }
            } else if entry.fields[relationshipName] == nil {
                relationships[propertyName] = DeletedRelationship()
            }
        }

        return relationships
    }


    // MARK: Regular properties.

    internal func updatePropertyFields(for entryModellable: EntryModellable,
                                       of type: EntryModellable.Type,
                                       with entry: Entry) {

        entryModellable.populateFields(from: entry.fields)
    }

    // Returns regular (non-relationship) field to property mappings.
    internal func propertyMapping(for entryType: EntryModellable.Type,
                                  and fields: [FieldName: Any]) -> [FieldName: String] {

        if let cachedPropertyMapping = cachedPropertyMappingForContentTypeId[entryType.contentTypeId] {
            return cachedPropertyMapping
        }

        // Get just the property names.
        let propertyNames = self.propertyNames(for: entryType)

        // If user-defined relationship properties exist, use them, but filter out relationships.
        let mapping = entryType.fieldMapping()
        let filteredMappingTuplesArray: [(FieldName, String)] = mapping.filter { (_, propertyName) -> Bool in
            // Get intersection with what the user-defined in their fieldMapping() function
            // and the properties returned by the reflection.
            return propertyNames.contains(propertyName) == true
        }
        let filteredMapping = Dictionary(elements: filteredMappingTuplesArray)

        // Cache.
        cachedPropertyMappingForContentTypeId[entryType.contentTypeId] = filteredMapping
        return mapping
    }

    // See if you can get the types of the class.
    internal func propertyNames(for type: EntryModellable.Type) -> [String] {

        // Create an empty instance of the current type so that we can introspect it's properties
        // using Swift's mirror API.
        let emptyInstance = type.init()
        let mirror = Mirror(reflecting: emptyInstance)

        let propertyNames: [String] = mirror.children.flatMap { propertyName, value in
            let type = type(of: value)

            // Filter out relationship names.
            if type is ContentModellable.Type {
                return nil
            } else if let optionalType = type as? OptionalProtocol.Type, optionalType.wrappedType() is ContentModellable.Type {
                return nil
            }
            return propertyName
        }

        return propertyNames
    }
    // MARK: Relationship resolution!

    func resolveRelationships() {

        // Dictionary mapping Entry id's concatenated with locale code to a dictionary with fieldName to related entry id's.
        //        internal var relationshipsToResolve = [String: [AnyKeyPath: Any]]()
        for (entryId, fields) in relationshipsToResolve {

            if let entryModellable = dataCache.entry(for: entryId) {

                let relationshipTuples: [(FieldName, Any)] = fields.flatMap { (fieldName, targetId) in

                    var transformedTarget: Any? = nil
                    if let identifier = targetId as? String {
                        transformedTarget = dataCache.item(for: identifier)
                    }

                    if let identifiers = targetId as? [String] {
                        transformedTarget = identifiers.flatMap { id in
                            return dataCache.item(for: id)
                        }
                    }
//                    assert(transformedTarget != nil)
                    guard let unwrappedTarget = transformedTarget else { return nil }

                    return (fieldName, unwrappedTarget)
                }

                let relationships = Dictionary(elements: relationshipTuples)

                entryModellable.populateLinks(from: relationships)
            }
        }
        self.relationshipsToResolve.removeAll()
    }
}

public struct MappedContent {

    public let assets: [AssetModellable]

    public let entries: [ContentTypeId: [EntryModellable]]
}

public extension ArrayResponse where ItemType: Entry {

    internal func map(entries: [Entry],
                      to entryType: EntryModellable.Type,
                      using contentModel: ContentModel) -> [EntryModellable] {

        let mappedEntriesForContentType: [EntryModellable] = entries.flatMap { entry in

            let mappedEntry: EntryModellable = entryType.init()

            // TODO: Fill in the other sys properties.
            mappedEntry.id = entry.sys.id
            mappedEntry.localeCode = entry.sys.locale

            // FIXME: Dry this code!
            // The key has locale information.
            let entryKey = DataCache.cacheKey(for: entry)

            // Populate fields.
            contentModel.updatePropertyFields(for: mappedEntry, of: entryType, with: entry)
            // Cache relationships to be resolved later.
            contentModel.relationshipsToResolve[entryKey] = contentModel.cachableRelationships(for: mappedEntry, of: entryType, with: entry)

            return mappedEntry
        }
        return mappedEntriesForContentType
    }

    internal func toMappedArrayResponse<EntryType>(for contentModel: ContentModel) -> MappedArrayResponse<EntryType> where EntryType: EntryModellable {

        let mappedContent = self.toMappedContent(for: contentModel)

        // TODO: ensure we are only returning the items not the includes.
        let mappedItems = mappedContent.entries[EntryType.contentTypeId] as! [EntryType]
        return MappedArrayResponse<EntryType>(items: mappedItems, limit: limit, skip: skip, total: total)
    }

    internal func toMappedContent(for contentModel: ContentModel) -> MappedContent {

        // Annoying workaround for type system not allowing cast of items to [Entry]
        let entries: [Entry] = items.flatMap { $0 as Entry }

        let allEntries = entries + (includedEntries ?? [])

        var mappedEntriesDictionary = [ContentTypeId: [EntryModellable]]()

        for entryType in contentModel.entryTypes { // iterate over all types in the content model.

            let entriesForContentType = allEntries.filter { $0.sys.contentTypeId == entryType.contentTypeId }

            let mappedEntriesForContentType = map(entries: entriesForContentType, to: entryType, using: contentModel)

            // Map to user-defined types.
            mappedEntriesDictionary[entryType.contentTypeId] = mappedEntriesForContentType

            mappedEntriesForContentType.forEach { entryModellable in
                contentModel.dataCache.add(entry: entryModellable)
            }
        }

        // Assets
        let allAssets = includedAssets ?? []

        let mappedAssets: [AssetModellable] = allAssets.flatMap { asset in
            let mappedAsset = contentModel.assetType?.init()
            mappedAsset?.id = asset.sys.id
            mappedAsset?.localeCode = asset.sys.locale

            // TODO: add to cache.
            return mappedAsset
        }

        //        // Resolve relationships.
        contentModel.resolveRelationships()

        let mappedContent = MappedContent(assets: mappedAssets, entries: mappedEntriesDictionary)

        return mappedContent
    }
}


// MARK: Utilities

extension Dictionary {

    // Helper initializer to allow declarative style Dictionary initialization using an array of tuples.
    init(elements: [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

// TOOD: Document that i'm using this to get the type that the optional wraps.
protocol OptionalProtocol {
    static func wrappedType() -> Any.Type
}

extension Optional: OptionalProtocol {
    static func wrappedType() -> Any.Type {
        return Wrapped.self
    }
}
