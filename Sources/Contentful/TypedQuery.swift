//
//  TypedQuery.swift
//  Contentful
//
//  Created by JP Wright on 12.10.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/// A protocol enabling strongly typed queries to the Contentful Delivery API via the SDK.
public protocol EntryQueryable {

    /// The CodingKey representing the names of each of the fields for the corresponding content type.
    /// These coding keys should be the same as those used when implementing Decodable.
    associatedtype Fields: CodingKey
}


public extension AbstractQuery {


    public static func `where`(sys key: Sys.CodingKeys, _ operation: Query.Operation) -> Self {
        return Self.where(valueAtKeyPath: "sys.\(key.stringValue)", operation)
    }

    public static func `where`(_ fieldsKey: CodingKey, _ operation: Query.Operation) -> Self {
        return Self.where(valueAtKeyPath: "fields.\(fieldsKey.stringValue)", operation)
    }
}

public extension ChainableQuery {

    // static version in Abstract query
    public func `where`(sys key: Sys.CodingKeys, _ operation: Query.Operation) -> Self {
        self.where(valueAtKeyPath: "sys.\(key.stringValue)", operation)
        return self
    }

    public func `where`(_ fieldsKey: CodingKey, _ operation: Query.Operation) -> Self {
        self.where(valueAtKeyPath: "fields.\(fieldsKey.stringValue)", operation)
        return self
    }

    public static func `where`(field fieldName: FieldName, _ operation: Query.Operation) -> Self {
        return Self.where(valueAtKeyPath: "fields.\(fieldName)", operation)
    }

    public func `where`(field fieldName: FieldName, _ operation: Query.Operation) -> Self {
        self.where(valueAtKeyPath: "fields.\(fieldName)", operation)
        return self
    }
}

public extension ResourceQuery {

    public static func select(fields fieldsKeys: [CodingKey]) throws -> Self {
        let query = Self()
        try query.select(fields: fieldsKeys)
        return query
    }

    @discardableResult public func select(fields fieldsKeys: [CodingKey]) throws -> Self {
        let fieldPaths = fieldsKeys.map { "fields.\($0.stringValue)" }
        try self.select(fieldsNamed: fieldPaths)
        return self
    }
}

/**
 An additional query to filter by the properties of linked objects when searching on references.
 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
 and see the init<LinkType: EntryDecodable>(whereLinkAt fieldNameForLink: String, matches filterQuery: FilterQuery<LinkType>? = nil) methods
 on QueryOn for example usage.
 */
public final class LinkQuery<EntryType>: AbstractQuery where EntryType: EntryDecodable & EntryQueryable {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    // Different function name to ensure inner call to where(valueAtKeyPath:operation:) doesn't recurse.
    private static func with(valueAtKeyPath keyPath: String, _ operation: Query.Operation) -> LinkQuery<EntryType> {
        let filterQuery = LinkQuery<EntryType>.where(valueAtKeyPath: keyPath, operation)
        filterQuery.propertyName = keyPath
        filterQuery.operation = operation
        return filterQuery
    }

    public static func `where`(field: EntryType.Fields, _ operation: Query.Operation) -> LinkQuery<EntryType> {
        return LinkQuery<EntryType>.with(valueAtKeyPath: "fields.\(field.stringValue)", operation)
    }

    /// Designated initializer for FilterQuery.
    public init() {
        self.parameters = [String: String]()
    }

    // MARK: FilterQuery<EntryType>.Private

    fileprivate var operation: Query.Operation!
    fileprivate var propertyName: String?
}

/**
 A concrete implementation of AbstractQuery which requires that a model class conforming to `EntryType`
 be passed in as a generic parameter.

 The "content_type" parameter of the query will be set to the `contentTypeID`
 of your `EntryType` conforming model class. `QueryOn<EntryType>` are chainable so complex queries can be constructed.
 Operations that are only available when querying `Entry`s on specific content types (i.e. content_type must be set)
 are available through this class.
 */
public final class QueryOn<EntryType>: EntryQuery where EntryType: EntryDecodable & EntryQueryable {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initializer for `QueryOn<EntryType>`.
    public init() {
        self.parameters = [QueryParameter.contentType: EntryType.contentTypeId]
    }

    public static func `where`(field fieldsKey: EntryType.Fields, _ operation: Query.Operation) -> QueryOn<EntryType> {
        let query = QueryOn<EntryType>.where(valueAtKeyPath: "fields.\(fieldsKey.stringValue)", operation)
        return query
    }

    public func `where`(field fieldsKey: EntryType.Fields, _ operation: Query.Operation) -> Self {
        self.where(valueAtKeyPath: "fields.\(fieldsKey.stringValue)", operation)
        return self
    }

    public static func select(fields fieldsKeys: [EntryType.Fields]) throws -> QueryOn<EntryType> {
        let query = QueryOn<EntryType>()
        try query.select(fields: fieldsKeys)
        return query
    }

    @discardableResult public func select(fields fieldsKeys: [EntryType.Fields]) throws -> QueryOn<EntryType> {
        let fieldPaths = fieldsKeys.map { "fields.\($0.stringValue)" }
        try self.select(fieldsNamed: fieldPaths)
        return self
    }

    /**
     Convenience initalizer for performing searches where Linked objects at the specified linking field match the filtering query.
     For instance, if you want to query all Entry's of type "cat" where cat's linked via the "bestFriend" field have names that match "Happy Cat"
     the code would look like the following:

     ```
     let filterQuery = FilterQuery<Cat>(field: .name, .matches("Happy Cat"))
     let query = QueryOn<Cat>(whereLinkAtField: .bestFriend, matches: filterQuery)
     client.fetchMappedEntries(with: query).observable.then { catsWithHappyCatAsBestFriendResponse in
     let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
     // Do stuff with catsWithHappyCatAsBestFriend
     }
     ```

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
     - Parameter fieldNameForLink: The name of the property which contains a link to another Entry.
     - Parameter filterQuery: The optional filter query applied to the linked objects which are being searched.
     set on the `Client` instance is used.
     */
    public static func `where`<LinkType>(linkAtField fieldsKey: EntryType.Fields, matches linkQuery: LinkQuery<LinkType>) -> QueryOn<EntryType> {
        let query = QueryOn<EntryType>()

        query.parameters["fields.\(fieldsKey.stringValue).sys.contentType.sys.id"] = LinkType.contentTypeId

        // If propertyName isn't unrwrapped, the string isn't constructed correctly for some reason.
        if let propertyName = linkQuery.propertyName {
            let filterParameterName = "fields.\(fieldsKey.stringValue).\(propertyName)\(linkQuery.operation.string)"
            query.parameters[filterParameterName] = linkQuery.operation.values
        }
        return query
    }
}

/// Queries on Asset types. All methods from Query, and therefore ChainableQuery, are inherited and available.
public final class AssetQuery: Query {
    /**
     Convenience intializer for creating an AssetQuery with the "mimetype_group" parameter specified. Example usage:

     ```
     let query = AssetQuery.where(mimetypeGroup: .image)
     ```

     - Parameter mimetypeGroup: The `mimetype_group` which all returned Assets will match.
     */
    public static func `where`(mimetypeGroup: MimetypeGroup) -> AssetQuery {
        let query = AssetQuery()
        query.where(mimetypeGroup: mimetypeGroup)
        return query
    }

    /**
     Instance method for mutating the query further to specify the mimetype group when querying assets.

     - Parameter mimetypeGroup: The `mimetype_group` which all returned Assets will match.
     */
    public func `where`(mimetypeGroup: MimetypeGroup) {
        self.parameters[QueryParameter.mimetypeGroup] = mimetypeGroup.rawValue
    }
}

public final class ContentTypeQuery: ChainableQuery {
    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initalizer for Query.
    public required init() {
        self.parameters = [String: String]()
    }
}
