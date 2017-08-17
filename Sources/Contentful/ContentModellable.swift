//
//  ContentModellable.swift
//  Contentful
//
//  Created by JP Wright on 15/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public typealias ContentTypeId = String

/**
 Classes conforming to this protocol can be passed into your ContentModel to leverage the type system 
 to return instances of your own model classes when using methods such as:

 ```
 func fetchMappedEntries(with query: Query,
    then completion: @escaping ResultsHandler<MappedContent>) -> URLSessionDataTask?
 ```
 */
public protocol EntryModellable: class {

    /// The identifier of the Contentful content type that will map to this type of `EntryPersistable`
    static var contentTypeId: ContentTypeId { get }

    /// The unique identifier of the Entry.
    var id: String { get }

    /// The code which represents which locale the Resource of interest contains data for.
    var localeCode: String { get }

    /// EntryModellable classes must implement this initializer, which should assign the identifier and localeCode
    /// and additionally map all fields that represent regular (non-relationship) fields to properties on the class.
    init(entry: Entry)

    /// Implement this method to complete the object graph on your model. The `cache` dictionary will contain already
    /// deserialized `EntryModellable`s of your own definition for fields which represent relationships on your model.
    func populateLinks(from cache: [FieldName: Any])
}

/**
 The ContentModel class contains the model of your application as it corresponds to your Content Model in Contentful.
 Contentful's polymorphic JSON API returns all content types as `Entry` instances with properties in the `fields` dictionary
 dependent on the identifier of the Content Type. However, switching on the content type of the `Entry` and then parsing the fields
 can sometimes be cumbersome. By initializing your `Client` instance with a `ContentModel` which holds references to all the model
 classes you have defined to be mapped from Contentful `Entry`s, you can utilize the relevant methods on `Client` to get back your own types.
 */
public class ContentModel {

    /// An array of model class types defined in your application which will be returned when using the relevant fetch methods on `Client`.
    public let entryTypes: [EntryModellable.Type]

    /**
     Initializes a new `ContentModel` instance.
     
     - Parameter entryTypes: References to the the types of your own definition, conforming to `EntryModellable`, which
                             which will be returned when using the relevant fetch methods on `Client`.
     */
    public init(entryTypes: [EntryModellable.Type]) {
        self.entryTypes = entryTypes
        self.dataCache = DataCache()
        self.cachedRelationshipNames = [ContentTypeId: [String]]()
    }


    internal let dataCache: DataCache

    // Small caches for optimizing mapping.
    internal var cachedRelationshipNames: [ContentTypeId: [String]]

    // Dictionary mapping source Entry id's concatenated with locale code to a dictionary with fieldName to related entry id's.
    internal var relationshipsToResolve = [String: [FieldName: Any]]()

    // See if you can get the types of the class.
    internal func relationshipNames(for entryType: EntryModellable.Type, use entry: Entry) -> [String] {
        if let cachedRelationshipNames = cachedRelationshipNames[entryType.contentTypeId] {
            return cachedRelationshipNames
        }

        // Create an empty instance of the current type so that we can introspect it's properties
        // using Swift's mirror API.
        let emptyInstance = entryType.init(entry: entry)
        let mirror = Mirror(reflecting: emptyInstance)

        let relationshipNames: [String] = mirror.children.flatMap { propertyName, value in
            let type = type(of: value)

            // Filter out relationship names.
            if type is EntryModellable.Type || type is Asset.Type {
                return propertyName
            } else if let optionalType = type as? OptionalProtocol.Type,
                optionalType.wrappedType() is EntryModellable.Type || optionalType.wrappedType() is Asset.Type {
                return propertyName
            }
            return nil
        }

        cachedRelationshipNames[entryType.contentTypeId] = relationshipNames
        return relationshipNames
    }

    // MARK: Relationships.

    // A type used to cache relationships that should be deleted in the `resolveRelationships()` method.
    fileprivate struct DeletedRelationship {}

    // Returns a dictionary representing the fields names and the target id(s) to create links to.
    fileprivate func cachableRelationships(for entryPersistable: EntryModellable,
                                           of type: EntryModellable.Type,
                                           with entry: Entry) -> [FieldName: Any] {

        // FieldName to either a single entry id or an array of entry id's to be linked.
        var relationships = [FieldName: Any]()

        let relationshipFieldNames = relationshipNames(for: type, use: entry)

        // Get fieldNames which are links/relationships/references to other types.
        for relationshipName in relationshipFieldNames {

            // Get the name of the property to be linked to.
            if let linkedValue = entry.fields[relationshipName] {
                if let targets = linkedValue as? [Link] {
                    // One-to-many.
                    relationships[relationshipName] = targets.map { ContentModel.cacheKey(for: $0, with: entry.currentlySelectedLocale.code) }
                } else {
                    // One-to-one.
                    assert(linkedValue is Link)
                    relationships[relationshipName] = ContentModel.cacheKey(for: (linkedValue as! Link), with: entry.currentlySelectedLocale.code)
                }
            } else if entry.fields[relationshipName] == nil {
                relationships[relationshipName] = DeletedRelationship()
            }
        }

        return relationships
    }

    fileprivate func resolveRelationships() {

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

                    guard let unwrappedTarget = transformedTarget else { return nil }
                    return (fieldName, unwrappedTarget)
                }

                let relationships = Dictionary(elements: relationshipTuples)

                entryModellable.populateLinks(from: relationships)
            }
        }
        relationshipsToResolve.removeAll()
    }

    internal static func cacheKey(for link: Link, with sourceLocaleCode: LocaleCode) -> String {
        let linkType: String
        switch link {
        case .asset:
            linkType = "asset"
        case .entry:
            linkType = "entry"
        default:
            fatalError()
        }
        let id = link.id
        let delimeter = "_"
        return id + delimeter + linkType + delimeter + sourceLocaleCode
    }
}

internal extension ArrayResponse where ItemType: Entry {

    internal func map(entries: [Entry],
                      to entryType: EntryModellable.Type,
                      using contentModel: ContentModel) -> [EntryModellable] {

        let mappedEntriesForContentType: [EntryModellable] = entries.flatMap { entry in

            let entryModellable: EntryModellable = entryType.init(entry: entry)

            // Cache relationships to be resolved later.
            let entryKey = DataCache.cacheKey(for: entry)
            contentModel.relationshipsToResolve[entryKey] = contentModel.cachableRelationships(for: entryModellable, of: entryType, with: entry)

            return entryModellable
        }
        return mappedEntriesForContentType
    }

    internal func toMappedArrayResponse<EntryType>(for contentModel: ContentModel) -> MappedArrayResponse<EntryType>
        where EntryType: EntryModellable {

        let mappedContent = self.toMappedContent(for: contentModel)

        let mappedItems = (mappedContent.entries[EntryType.contentTypeId] as! [EntryType]).filter { entryModellable in
            // Only forward the "items" member of the original JSON.
            return items.flatMap({ $0.id }).contains(entryModellable.id)
        }

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

            // Cache the mapped entry so links may be resolved later.
            mappedEntriesForContentType.forEach { entryModellable in
                contentModel.dataCache.add(entry: entryModellable)
            }
        }

        // Assets
        let allAssets = includedAssets ?? []
        for asset in allAssets {
            // Cache the asset so links may be resolved later.
            contentModel.dataCache.add(asset: asset)
        }

        // Resolve relationships.
        contentModel.resolveRelationships()

        let mappedContent = MappedContent(assets: allAssets, entries: mappedEntriesDictionary)

        return mappedContent
    }
}


// MARK: Utilities

internal extension Dictionary {

    // Helper initializer to allow declarative style Dictionary initialization using an array of tuples.
    init(elements: [(Key, Value)]) {
        self.init()
        for (key, value) in elements {
            updateValue(value, forKey: key)
        }
    }
}

// Convenience protocol and accompanying extension for extracting the type of data wrapped in an Optional.
internal protocol OptionalProtocol {
    static func wrappedType() -> Any.Type
}

extension Optional: OptionalProtocol {
    static func wrappedType() -> Any.Type {
        return Wrapped.self
    }
}
