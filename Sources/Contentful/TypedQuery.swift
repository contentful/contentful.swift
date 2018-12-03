//
//  TypedQuery.swift
//  Contentful
//
//  Created by JP Wright on 12.10.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/// A concrete implementation of ChainableQuery which can be used to make queries on `/entries/`
/// or `/entries`. All methods from ChainableQuery are available.
public class Query: ResourceQuery, EntryQuery {

    public static var any: Query {
        return Query()
    }
}

/// An additional query to filter by the properties of linked objects when searching on references.
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
/// and see the init<LinkType: EntryDecodable>(whereLinkAt fieldNameForLink: String, matches filterQuery: FilterQuery<LinkType>? = nil) methods
/// on QueryOn for example usage.
public final class LinkQuery<EntryType>: AbstractQuery where EntryType: EntryDecodable & FieldKeysQueryable {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    // Different function name to ensure inner call to where(valueAtKeyPath:operation:) doesn't recurse.
    private static func with(valueAtKeyPath keyPath: String, _ operation: Query.Operation) -> LinkQuery<EntryType> {
        let filterQuery = LinkQuery<EntryType>.where(valueAtKeyPath: keyPath, operation)
        filterQuery.propertyName = keyPath
        filterQuery.operation = operation
        return filterQuery
    }

    /// Static method for creating a new LinkQuery with an operation. This variation for initializing guarantees
    /// correct query contruction by utilizing the associated Fields CodingKeys type required by ResourceQueryable on the type you are linking to.
    ///
    /// Example usage:
    ///
    /// ```
    /// let linkQuery = LinkQuery<Cat>.where(field: .name, .matches("Happy Cat"))
    /// let query = QueryOn<Cat>(whereLinkAtField: .bestFriend, matches: linkQuery)
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
    ///
    /// - Parameters:
    ///   - field: The member of the `FieldKeys` type associated with your type conforming to `EntryDecodable & ResourceQueryable`
    ///            that you are performing your search on reference against.
    ///   - operation: The query operation used in the query.
    /// - Returns: A newly initialized `QueryOn` query.
    public static func `where`(field: EntryType.FieldKeys, _ operation: Query.Operation) -> LinkQuery<EntryType> {
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

/// A concrete implementation of EntryQuery which requires that a model class conforming to `EntryType`
/// be passed in as a generic parameter.
/// The "content_type" parameter of the query will be set using the `contentTypeID` of the generic parameter conforming
/// to `EntryDecodable`. You must also implement `ResourceQueryable` in order to utilize these generic queries.
public final class QueryOn<EntryType>: EntryQuery where EntryType: EntryDecodable & FieldKeysQueryable {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initializer for `QueryOn<EntryType>`.
    public init() {
        self.parameters = [QueryParameter.contentType: EntryType.contentTypeId]
    }

    /// Static method for creating a new `QueryOn` with an operation. This variation for initialization guarantees correct query construction
    /// by utilizing the associated `FieldKeys` type required by `ResourceQueryable`.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = QueryOn<Cat>.where(field: .color, .equals("gray"))
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
    /// - Parameters:
    ///   - field: The member of the `FieldKeys` type associated with your type conforming to `EntryDecodable & ResourceQueryable`
    ///            that you are performing your select operation against.
    ///   - operation: The query operation used in the query.
    /// - Returns: A newly initialized `QueryOn` query.
    public static func `where`(field fieldsKey: EntryType.FieldKeys, _ operation: Query.Operation) -> QueryOn<EntryType> {
        let query = QueryOn<EntryType>.where(valueAtKeyPath: "fields.\(fieldsKey.stringValue)", operation)
        return query
    }

    /// Instance method for appending a query operation to the receiving `QueryOn`.
    /// This variation for initialization guarantees correct query contruction by utilizing the associated
    /// `FieldKeys` type required by `ResourceQueryable`.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = QueryOn<Cat>().where(field: .color, .equals("gray"))
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
    ///
    /// - Parameters:
    ///   - fieldsKey: The member of your `FieldKeys` type associated with your type conforming to `EntryDecodable & ResourceQueryable`
    ///                that you are performing your select operation against.
    ///   - operation: The query operation used in the query.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    public func `where`(field fieldsKey: EntryType.FieldKeys, _ operation: Query.Operation) -> QueryOn<EntryType> {
        self.where(valueAtKeyPath: "fields.\(fieldsKey.stringValue)", operation)
        return self
    }

    /// Static method for creating a new QueryOn with a select operation: an operation in which only
    /// the fields specified in the fieldNames property will be returned in the JSON response. This variation for initializing guarantees correct query contruction
    /// by utilizing the Fields CodingKeys required by ResourceQueryable.
    /// The "sys" dictionary is always requested by the SDK.
    /// Note that if you are using the select operator with an instance `QueryOn<EntryType>`
    /// that your model types must have optional types for properties that you are omitting in the response (by not including them in your selections array).
    /// If you are not using the `QueryOn` type while querying entries, make sure to specify the content type id.
    /// Example usage:
    ///
    /// ```
    /// let query = QueryOn<Cat>.select(fieldsNamed: [.bestFriend, .color, .name])
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator>
    ///
    /// - Parameter fieldsKeys: An array of `FieldKeys` associated with the genery `EntryType` that you are performing your select operation against.
    /// - Returns: A newly initialized QueryOn query.
    public static func select(fieldsNamed fieldsKeys: [EntryType.FieldKeys]) -> QueryOn<EntryType> {
        let query = QueryOn<EntryType>()
        query.select(fieldsNamed: fieldsKeys)
        return query
    }

    /// Instance method for creating a new QueryOn with a select operation: an operation in which only
    /// the fields specified in the fieldNames property will be returned in the JSON response. This variation for initializing guarantees correct query contruction
    /// by utilizing the Fields type associated with your type conforming to ResourceQueryable.
    /// The "sys" dictionary is always requested by the SDK.
    /// Note that if you are using the select operator with an instance `QueryOn<EntryType>`
    /// that your model types must have optional types for properties that you are omitting in the response (by not including them in your selections array).
    /// If you are not using the `QueryOn` type while querying entries, make sure to specify the content type id.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = QueryOn<Cat>().select(fieldsNamed: [.bestFriend, .color, .name])
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator>
    ///
    /// - Parameter fieldsKeys: An array of `FieldKeys` associated with the genery `EntryType` that you are performing your select operation against.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    public func select(fieldsNamed fieldsKeys: [EntryType.FieldKeys]) -> QueryOn<EntryType> {
        let fieldPaths = fieldsKeys.map { $0.stringValue }
        try! self.select(fieldsNamed: fieldPaths)
        return self
    }

    /// Static method for performing searches where linked entries or assets at the specified linking field match the filtering query.
    /// For instance, if you want to query all entries of type "cat" where the "bestFriend" field links to cats with name matching "Happy Cat"
    /// the code would look like the following:
    ///
    /// ```
    /// let linkQuery = LinkQuery<Cat>.where(field: .name, .matches("Happy Cat"))
    /// let query = QueryOn<Cat>(whereLinkAtField: .bestFriend, matches: linkQuery)
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
    ///
    /// - Parameters:
    ///   - fieldsKey: The `FieldKey` for the property which contains a link to another entry.
    ///   - linkQuery: The filter query applied to the linked objects which are being searched.
    /// - Returns: A newly initialized `QueryOn` query.
    public static func `where`<LinkType>(linkAtField fieldsKey: EntryType.FieldKeys,
                                         matches linkQuery: LinkQuery<LinkType>) -> QueryOn<EntryType> {
        let query = QueryOn<EntryType>()
        query.where(linkAtField: fieldsKey, matches: linkQuery)
        return query
    }

    /// Instance method for for performing searches where Linked objects at the specified linking field match the filtering query.
    /// For instance, if you want to query all entries of type "cat" where the "bestFriend" field links to cats with name matching "Happy Cat"
    /// the code would look like the following:
    ///
    /// ```
    /// let linkQuery = LinkQuery<Cat>.where(field: .name, .matches("Happy Cat"))
    /// let query = QueryOn<Cat>(whereLinkAtField: .bestFriend, matches: linkQuery)///
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
    ///
    /// - Parameters:
    ///   - fieldsKey: The `FieldKey` for the property which contains a link to another entry or asset.
    ///   - linkQuery: The filter query applied to the linked objects which are being searched.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    public func `where`<LinkType>(linkAtField fieldsKey: EntryType.FieldKeys,
                                                     matches linkQuery: LinkQuery<LinkType>) -> QueryOn<EntryType> {

        parameters["fields.\(fieldsKey.stringValue).sys.contentType.sys.id"] = LinkType.contentTypeId

        // If propertyName isn't unrwrapped, the string isn't constructed correctly for some reason.
        if let propertyName = linkQuery.propertyName {
            let filterParameterName = "fields.\(fieldsKey.stringValue).\(propertyName)\(linkQuery.operation.string)"
            parameters[filterParameterName] = linkQuery.operation.values
        }
        return self
    }

    /// Static method fore creating a query requiring that a specific field of an entry
    /// contains a reference to another specific entry.
    ///
    /// ```
    /// let query = QueryOn<Cat>(whereLinkAtField: .bestFriend, hasTargetId: "nyancat")
    ///
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
    ///
    /// - Parameters:
    ///   - fieldsKey: The `FieldKey` of the property which contains a link to another Entry.
    ///   - targetId: The identifier of the entry or asset being linked to at the specified linking field.
    /// - Returns: A newly initialized `QueryOn` query.
    public static func `where`(linkAtField fieldsKey: EntryType.FieldKeys,
                               hasTargetId targetId: String) -> QueryOn<EntryType> {
        let query = QueryOn<EntryType>()
        query.where(linkAtField: fieldsKey, hasTargetId: targetId)
        return query
    }

    /// Instance method creating a query that requires that an specific field of an entry
    /// holds a reference to another specific entry.
    ///
    /// ```
    /// let query = QueryOn<Cat>(whereLinkAtField: .bestFriend, hasTargetId: "nyancat")
    ///
    /// client.fetchArray(of: Cat.self, matching: query) { (result: Result<ArrayResponse<Cat>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let cats = arrayResponse.items
    ///         // Do stuff with cats.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
    ///
    /// - Parameters:
    ///   - fieldsKey: The `FieldKey` of the property which contains a link to another Entry.
    ///   - targetId: The identifier of the entry or asset being linked to at the specified linking field.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    public func `where`(linkAtField fieldsKey: EntryType.FieldKeys,
                        hasTargetId targetId: String) -> QueryOn<EntryType> {

        let filterParameterName = "fields.\(fieldsKey.stringValue).sys.id"
        parameters[filterParameterName] = targetId

        return self
    }
}

/// Queries on Asset types. All methods from `ChainableQuery` are available.
public final class AssetQuery: ResourceQuery {

    /// Convenience initializer for creating an `AssetQuery` with the "mimetype_group" parameter specified. Example usage:
    ///
    /// ```
    /// let query = AssetQuery.where(mimetypeGroup: .image)
    /// ```
    ///
    /// - Parameter mimetypeGroup: The `mimetype_group` which all returned Assets will match.
    /// - Returns: A newly initialized `AssetQuery` query.
    public static func `where`(mimetypeGroup: MimetypeGroup) -> AssetQuery {
        let query = AssetQuery()
        query.where(mimetypeGroup: mimetypeGroup)
        return query
    }

    /// Instance method for mutating the query further to specify the mimetype group when querying assets.
    ///
    /// - Parameter mimetypeGroup: The `mimetype_group` which all returned Assets will match.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    public func `where`(mimetypeGroup: MimetypeGroup) -> AssetQuery {
        self.parameters[QueryParameter.mimetypeGroup] = mimetypeGroup.rawValue
        return self
    }

    /// Static method for creating a new `AssetQuery` with a select operation: an operation in which only
    /// the fields specified in the fieldNames parameter will be returned in the JSON response.
    /// This variation for initialization guarantees correct query contruction by utilizing the typesafe `Asset.FieldKeys`.
    /// The "sys" dictionary is always requested by the SDK.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = AssetQuery.select(fieldsNamed: [.file])
    /// client.fetchArray(of: Asset.self, matching: query) { (result: Result<ArrayResponse<Asset>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let assets = arrayResponse.items
    ///         // Do stuff with assets.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator>
    ///
    /// - Parameter fieldsKeys: An array of `Asset.FieldKeys` of the asset you are performing your select operation against.
    /// - Returns: A newly initialized `AssetQuery` query.
    public static func select(fields fieldsKeys: [Asset.Fields]) -> AssetQuery {
        let query = AssetQuery()
        query.select(fields: fieldsKeys)
        return query
    }

    /// Instance method for mutating an `AssetQuery` with a select operation: an operation in which only
    /// the fields specified in the fieldNames parameter will be returned in the JSON response.
    /// This variation for initialization guarantees correct query contruction by utilizing the typesafe `Asset.FieldKeys`.
    /// The "sys" dictionary is always requested by the SDK.
    ///
    /// ```
    /// let query = AssetQuery.select(fieldsNamed: [.file])
    /// client.fetchMappedEntries(with: query).then { catsResponse in
    ///     let cats = catsResponse.items
    ///     // Do stuff with cats.
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator>
    ///
    /// - Parameter fieldsKeys: An array of `Asset.FieldKeys` of the asset you are performing your select operation against.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    public func select(fields fieldsKeys: [Asset.Fields]) -> AssetQuery {
        let fieldPaths = fieldsKeys.map { $0.stringValue }
        // Because we're guaranteed the keyPath doesn't have a "." in it, we can force try
        try! self.select(fieldsNamed: fieldPaths)
        return self
    }
}

/// Queries on content types. All methods from ChainableQuery are available, are inherited and available.
public final class ContentTypeQuery: ChainableQuery {
    /// The parameters dictionary that is converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initalizer for Query.
    public required init() {
        self.parameters = [String: String]()
    }


    /// Static method for creating a ContentTypeQuery with an operation.
    /// This variation for initializing guarantees correct query contruction by utilizing the ContentType.QueryableCodingKey CodingKeys.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = ContentTypeQuery.where(queryableCodingKey: .name, .equals("Cat"))
    /// client.fetchArray(of: ContentType.self, matching: query) { (result: Result<ArrayResponse<ContentType>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let contentTypes = arrayResponse.items
    ///         // Do stuff with contentTypes.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
    ///
    /// - Parameters:
    ///   - queryableCodingKey: The member of your `ContentType.QueryableCodingKey` that you are performing your operation against.
    ///   - operation: The query operation used in the query.
    /// - Returns: A newly initialized `AssetQuery` query.
    public static func `where`(queryableCodingKey: ContentType.QueryableCodingKey, _ operation: Query.Operation) -> ContentTypeQuery {
        let query = ContentTypeQuery()
        query.where(valueAtKeyPath: "\(queryableCodingKey.stringValue)", operation)
        return query
    }

    /// Instance method for appending a query operation to the receiving ContentTypeQuery.
    /// This variation for initializing guarantees correct query construction by utilizing the ContentType.QueryableCodingKey CodingKeys.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = ContentTypeQuery().where(queryableCodingKey: .name, .equals("Cat"))
    /// client.fetchArray(of: ContentType.self, matching: query) { (result: Result<ArrayResponse<ContentType>>) in
    ///     switch result {
    ///     case .success(let arrayResponse):
    ///         let contentTypes = arrayResponse.items
    ///         // Do stuff with contentTypes.
    ///     case .error(let error):
    ///         print(error)
    ///     }
    /// }
    /// ```
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
    ///
    /// - Parameters:
    ///   - queryableCodingKey: The member of your `ContentType.QueryableCodingKey` that you are performing your operation against.
    ///   - operation: The query operation used in the query.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    public func `where`(queryableCodingKey: ContentType.QueryableCodingKey, _ operation: Query.Operation) -> ContentTypeQuery {
        self.where(valueAtKeyPath: "\(queryableCodingKey.stringValue)", operation)
        return self
    }
}
