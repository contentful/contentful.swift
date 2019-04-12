//
//  Query.swift
//  Contentful
//
//  Created by JP Wright on 06/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/// The available URL parameter names for queries; used internally by the various `Contentful.Query` types.
/// Use these static variables to avoid making typos when constructing queries. It is recommended to take
/// advantage of `Client` "fetch" methods that take `Query` types instead of constructing query dictionaries on your own.
public enum QueryParameter {

    /// The parameter for specifying the content type of returned entries.
    public static let contentType      = "content_type"

    /// The parameter name for incoming links to an entry: See <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/links-to-entry>
    public static let linksToEntry     = "links_to_entry"

    /// The parameter name for incoming links to an asset: See <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/links-to-asset>
    public static let linksToAsset     = "links_to_asset"

    /// The [select operator](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator)
    public static let select           = "select"

    /// The [order parameter](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order)
    public static let order            = "order"

    /// Limit the number of items allowed in a response. See [limit](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/limit).
    public static let limit            = "limit"

    /// The offset to be used with `limit` for pagination. See [Skip](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/skip).
    public static let skip             = "skip"

    /// The level depth of including resources to resolve. See [Links](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/links)
    public static let include          = "include"

    /// The locale that you want to localize your responses to. See [Localization](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/localization)
    public static let locale           = "locale"

    /// A query parameter to [filter assets by the mimetype](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/filtering-assets-by-mime-type)
    /// of the referenced binary file
    public static let mimetypeGroup    = "mimetype_group"

    /// Use this to pass in a query to search accross all text and symbol fields in your space. See [Full-text search](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/full-text-search)
    public static let fullTextSearch   = "query"
}

/// A small class to create parameters used for ordering the responses when querying an endpoint
/// that returns a colleciton of resources.
/// See: `ChainableQuery.order(by order: Ordering...)`
public class Ordering {

    /// Initializes a new `Ordering` operator.
    ///
    /// - Parameters:
    ///   - propertyKeyPath: The key path of the property you are performing the Query.Operation` against. For instance,
    ///         `"sys.id"`
    ///   - inReverse: Specifies if the ordering by the sys parameter should be reversed or not. Defaults to `false`.
    /// - Throws: An error if the keypaths specified in the ordering are not valid.
    public init(_ propertyKeyPath: String, inReverse: Bool = false) throws {
        try Ordering.validateKeyPath(propertyKeyPath)
        // If validation fails, control flow will not reach here.
        self.reverse = inReverse
        self.propertyKeyPath = propertyKeyPath
    }

    /// Initializes a new `Ordering` operator.
    ///
    /// - Parameters:
    ///   - sys: The `Sys.CodingKey` of the system property you are performing the `Query.Operation` against.
    ///   - inReverse: Specifies if the ordering by the sys parameter should be reversed or not. Defaults to `false`.
    /// - Throws: An error if the keypaths specified in the ordering are not valid.
    public convenience init(sys: Sys.CodingKeys, inReverse: Bool = false) throws {
        try self.init("sys.\(sys.stringValue)", inReverse: inReverse)
    }

    private static func validateKeyPath(_ propertyKeyPath: String) throws {
        if propertyKeyPath.hasPrefix("fields.") == false && propertyKeyPath.hasPrefix("sys.") == false {
            throw QueryError.invalidOrderProperty
        }
    }

    internal var parameterValue: String {
        if reverse {
            return "-\(propertyKeyPath)"
        } else {
            return propertyKeyPath
        }
    }

    internal let propertyKeyPath: String
    internal let reverse: Bool
}

/// A small class to create parameters used for ordering the responses when querying an endpoint
/// that returns a collection of resources. This variation of an ordering takes a generic type parameter that
/// conforms to `ResourceQueryable` in order to take advantage of the `FieldKeys` available on your type.
/// See: `ChainableQuery.order(by order: Ordering...)`
public class Ordered<EntryType>: Ordering where EntryType: FieldKeysQueryable {

    /// Initializes a new `Ordering<EntryType>` operator.
    ///
    /// - Parameters:
    ///   - field: The member of `FieldKeys` used to order your results.
    ///   - inReverse: Specifies if the ordering by the sys parameter should be reversed or not. Defaults to `false`.
    /// - Throws: An error if the keypaths specified in the ordering are not valid.
    public init(field: EntryType.FieldKeys, inReverse: Bool = false) throws {
        try super.init("fields.\(field.stringValue)", inReverse: inReverse)
    }
}

internal enum QueryConstants {
    internal static let maxLimit: UInt               = 1000
    internal static let maxSelectedProperties: UInt  = 99
    internal static let maxIncludes: UInt            = 10
}

/// Use types that conform to QueryableRange to perform queries with the four Range operators
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges>
public protocol QueryableRange {

    /// A string representation of a query value that can be used in an API query.
    var stringValue: String { get }
}

extension Int: QueryableRange {

    public var stringValue: String {
        return String(self)
    }
}

extension String: QueryableRange {

    public var stringValue: String {
        return self
    }
}

extension Date: QueryableRange {

    /// The ISO8601 string representation of the receiving Date object.
    public var stringValue: String {
        return self.iso8601String
    }
}

/// Use bounding boxes or bounding circles to perform queries on location-enabled content.
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/locations-in-a-bounding-object>
public enum Bounds {
    /// A bounding box, defined by bottom left and top right corners.
    case box(bottomLeft: Contentful.Location, topRight: Contentful.Location)
    /// A circle defined by its center and radius.
    case circle(center: Contentful.Location, radius: Double)
}

//  Developer note: Cases in String backed Swift enums have a raw value equal to the case name.
//  i.e. MimetypeGroup.attachement.rawValue = "attachment"
/// All the possible MIME types that are supported by Contentful. \
public enum MimetypeGroup: String {
    /// The attachment mimetype.
    case attachment
    /// The plaintext mimetype.
    case plaintext
    /// The image mimetype.
    case image
    /// The audio mimetype.
    case audio
    /// The video mimetype.
    case video
    /// The richtext mimetype.
    case richtext
    /// The presentation mimetype.
    case presentation
    /// The spreadsheet mimetype.
    case spreadsheet
    /// The pdf document mimetype.
    case pdfdocument
    /// The archive mimetype.
    case archive
    /// The code mimetype.
    case code
    /// The markup mimetype.
    case markup
}

/// A base abtract type which holds the bare essentials shared by all query types in the SDK which enable
/// querying against content types, entries and assets.
public protocol AbstractQuery: class {

    /// A compiler-forced, required, and designated initializer. Creates affordance that the default implementation
    /// of AbstractQuery guarantees an object is constructed before doing additional mutations in convenience initializers.
    init()

    /// The parameters dictionary that are converted to `URLComponents` on the HTTP URL. Useful for debugging.
    var parameters: [String: String] { get set }
}

// MARK: - KeyPath/Value operations.
public extension AbstractQuery {

    /// Static method for creating a `Query` with a `Query.Operation`. This variation for initialization guarantees correct query construction
    /// when performing operations on "sys" members. See the concrete types `Query`, `FilterQuery`, `AssetQuery`, and `QueryOn`
    /// for more information and example usage.
    ///
    /// - Parameters:
    ///   - key: The `Sys.CodingKeys` of the system property you are performing the `Query.Operation` against. For instance, `.id`.
    ///   - operation: The query operation used in the query.
    /// - Returns: A newly initialized query.
    static func `where`(sys key: Sys.CodingKeys, _ operation: Query.Operation) -> Self {
        return Self.where(valueAtKeyPath: "sys.\(key.stringValue)", operation)
    }

    /// Static method for creating a Query with a Query.Operation. See concrete types `Query`, `FilterQuery`, `AssetQuery`, and `QueryOn`
    /// for more information and example usage.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property you are performing the Query.Operation against. For instance,
    ///              `"sys.id"` or `"fields.yourFieldName"`.
    ///   - operation: The query operation used in the query.
    /// - Returns: A newly initialized query.
    static func `where`(valueAtKeyPath keyPath: String, _ operation: Query.Operation) -> Self {
        let parameter = keyPath + operation.string

        let query = Self()
        query.parameters[parameter] = operation.values

        return query
    }

    internal init(parameters: [String: String]) {
        self.init()
        self.parameters = parameters
    }
}

/// Protocol which enables concrete query implementations to be 'chained' together so that results
/// can be filtered by more than one `Query.Operation` or other query. Protocol extensions give default implementation
/// so that all concrete types, `Query`, `AssetQuery`, `FilterQuery`, and `QueryOn<EntryType>`, can use the same implementation.
public protocol ChainableQuery: AbstractQuery {}
public extension ChainableQuery {

    /// Instance method for appending a `Query.Operation` to a `Query`. This variation for creating a query guarantees correct query construction
    /// when performing operations on "sys" members. See concrete types `Query`, `FilterQuery`, `AssetQuery`, and `QueryOn`
    /// for more information and example usage.
    ///
    /// - Parameters:
    ///   - key: The `Sys.CodingKey` of the system property you are performing the Query.Operation against. For instance, `.id`.
    ///   - operation: The query operation used in the query.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(sys key: Sys.CodingKeys, _ operation: Query.Operation) -> Self {
        self.where(valueAtKeyPath: "sys.\(key.stringValue)", operation)
        return self
    }

    /// Static method for creating a Query with a Query.Operation. This variation for creating a query guarantees correct query contruction
    /// when performing operations on "sys" members. See concrete types Query, FilterQuery, AssetQuery, and QueryOn
    /// for more information and example usage.
    ///
    /// - Parameters:
    ///   - fieldName:  The string name of the field that the `Query.Operation` is matching against. For instance, ".name"
    ///   - operation: The query operation used in the query.
    /// - Returns: A newly initialized query.
    static func `where`(field fieldName: FieldName, _ operation: Query.Operation) -> Self {
        return Self.where(valueAtKeyPath: "fields.\(fieldName)", operation)
    }

    /// Instance method for appending a Query.Operation to a Query. This variation for creating a query guarantees correct query contruction
    /// when performing operations on "field" members. See concrete types Query, FilterQuery, AssetQuery, and QueryOn
    /// for more information and example usage.
    ///
    /// - Parameters:
    ///   - fieldName: The string name of the field that the `Query.Operation` is matching against. For instance, "name"
    ///   - operation: The query operation used in the query.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(field fieldName: FieldName, _ operation: Query.Operation) -> Self {
        self.where(valueAtKeyPath: "fields.\(fieldName)", operation)
        return self
    }

    /// Instance method for appending more `Query.Operation`s to further filter results on the API. Example usage:
    ///
    /// ```
    /// let query = Query.where(contentTypeId: "cat").where("fields.color", .doesNotEqual("gray"))
    ///
    /// // Mutate the query further.
    /// query.where(valueAtKeyPath: "fields.lives", .equals("9"))
    /// ```
    ///
    /// - Parameters:
    ///   - keyPath: The key path for the property you are performing the Query.Operation against. For instance,
    ///              `"sys.id" or `"fields.yourFieldName"`.
    ///   - operation: The query operation used in the query.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(valueAtKeyPath keyPath: String, _ operation: Query.Operation) -> Self {

        // Create parameter for this query operation.
        let parameter = keyPath + operation.string
        self.parameters[parameter] = operation.values
        return self
    }

    // MARK: - Full-text search

    /// Convenience initializer for querying entries or assets in which all text and symbol fields contain
    /// the specified, case-insensitive text parameter.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/full-text-search>
    ///
    /// - Parameter text: The text string to match against.
    /// - Returns: A newly initialized query.
    /// - Throws: A `QueryError` if the text being searched for is 1 character in length or less.
    static func searching(for text: String) throws -> Self {
        let query = Self()
        try query.searching(for: text)
        return query
    }

    /// Instance method for appending a full-text search query to an existing query. Returned results will contain
    /// either entries or assets in which all text and symbol fields contain the specified, case-insensitive text parameter.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/full-text-search>
    ///
    /// - Parameter text: The text string to match against.
    /// - Returns: A reference to the receiving query to enable chaining.
    /// - Throws: A `QueryError` if the text being searched for is 1 character in length or less.
    @discardableResult
    func searching(for text: String) throws -> Self {
        guard text.count > 1 else { throw QueryError.textSearchTooShort }
        self.parameters[QueryParameter.fullTextSearch] = text
        return self
    }

    // MARK: - Response Manipulations.

    /// Static method for specifiying the level of includes to be resolved in the JSON response.
    /// The maximum permitted level of includes at the API level is 10; the SDK will limit the includes level at 10
    /// before the network request is made if the passed in value is too high in order to avoid
    /// hitting an error from the API.
    /// To omit all linked items, specify an include level of 0.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/links/retrieval-of-linked-items>
    ///
    /// - Parameter includesLevel: An unsigned integer specifying the level of includes to be resolved.
    /// - Returns: A newly constructed query object specifying the level of includes to be linked.
    static func include(_ includesLevel: UInt) -> Self {
        let query = Self()
        query.include(includesLevel)
        return query
    }

    /// Specify the level of includes to be resolved in the JSON response.
    /// The maximum permitted level of includes at the API level is 10; the SDK will round down to the 10
    /// before the network request is made if the passed in value is too high in order to avoid
    /// hitting an error from the API.
    /// To omit all linked items, specify an include level of 0.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/links/retrieval-of-linked-items>
    ///
    /// - Parameter includesLevel: An unsigned integer specifying the level of includes to be resolved.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func include(_ includesLevel: UInt) -> Self {
        let includes = min(includesLevel, QueryConstants.maxIncludes)
        self.parameters[QueryParameter.include] = String(includes)
        return self
    }

    /// Static method for creating a query that specifies that the first `n` items in a collection should be skipped
    /// before returning the results.
    /// Use in conjunction with the `limit(to:)` and `order(by:)` methods to paginate responses.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = Query.skip(theFirst: 9)
    /// ```
    ///
    /// - Parameter numberOfResults: The number of results that will be skipped in the query.
    /// - Returns: A newly constructed query object specifying the number of items to skip.
    static func skip(theFirst numberOfResults: UInt) -> Self {
        let query = Self()
        query.skip(theFirst: numberOfResults)
        return query
    }

    /// Instance method for further mutating a query to skip the first `n` items in a response.
    /// Use in conjunction with the `limit(to:)` and `order(by:)` methods to paginate responses.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = Query().skip(theFirst: 10)
    /// ```
    ///
    /// - Parameter numberOfResults: The number of results that will be skipped in the query.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func skip(theFirst numberOfResults: UInt) -> Self {
        self.parameters[QueryParameter.skip] = String(numberOfResults)
        return self
    }

    /// Convenience initializer for a ordering responses by the values at the specified field. Field types that can be
    /// specified are strings, numbers, or booleans.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = try! Query(orderBy: OrderParameter("sys.createdAt"))
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order>
    /// and: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order-with-multiple-parameters>
    ///
    /// - Parameter order: The specified `Ordering`.
    /// - Returns: A newly constructed query object specifying the order of the results.
    static func order(by order: Ordering...) -> Self {
        let query = Self()
        query.order(by: order)
        return query
    }

    /// Instance method for ordering responses by the values at the specified field. Field types that can be
    /// specified are strings, numbers, or booleans.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = try! Query().order(by: Ordering(sys: .createdAt))
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order>
    /// and: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order-with-multiple-parameters>
    ///
    /// - Parameter order: The specified Ordering.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func order(by order: Ordering...) -> Self {
        return self.order(by: order)
    }

    // Helper to workaround Swift bug/issue: Despite the fact that Variadic's can be passed into
    // to functions expecting an `Array`, instances of `Array`
    // cannot be passed into a function expecting a variadic parameter.
    @discardableResult
    private func order(by order: [Ordering]) -> Self {
        let propertyPathsWithReversals = order.map { return $0.parameterValue }
        let joinedPropertyNames = propertyPathsWithReversals.joined(separator: ",")

        self.parameters[QueryParameter.order] = joinedPropertyNames
        return self
    }

    /// Static method for creating a query that limits responses to a certain number of values. Use in conjunction with the `skip` method
    /// to paginate responses. The maximum number of items that can be returned by the API on one page is 1000. The SDK will limit your value
    /// to 1000 if you pass in something larger in order to avoid getting an error returned from the delivery API.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = Query.limit(to: 10)
    /// ```
    ///
    /// - Parameter numberOfResults: The number of results the response will be limited to.
    /// - Returns: A newly constructed query object specifying the number of resuls to be returned.
    static func limit(to numberOfResults: UInt) -> Self {
        let query = Self()
        query.limit(to: numberOfResults)
        return query
    }

    /// Instance method for further mutating a query to limit responses to a certain number of values. Use in conjunction with the `skip` method
    /// to paginate responses. The maximum number of items that can be returned by the API on one page is 1000. The SDK will truncate your value
    /// to 1000 if you pass in something larger in order to avoid getting an error returned from the delivery API.
    /// Use in conjunction with the `skip(theFirst:)` and `order(by:)` methods to paginate responses.
    /// Example usage:
    ///
    /// ```
    /// let query = try! Query().limit(to: 10)
    /// ```
    ///
    /// - Parameter numberOfResults: The number of results the response will be limited to.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func limit(to numberOfResults: UInt) -> Self {
        let limit = min(numberOfResults, QueryConstants.maxLimit)

        self.parameters[QueryParameter.limit] = String(limit)
        return self
    }
}

/// A base abtract type which holds methods and constructors for all valid queries against resource: i.e. Contentful entries and assets.
public protocol AbstractResourceQuery: ChainableQuery {}
public extension AbstractResourceQuery {

    /// Static method to create a query which specifies the locale of the entries that should be returned.
    /// If there's no content available for the requested locale the API will try the fallback locale of the requested locale.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/localization/retrieve-localized-entries>
    ///
    ///
    /// - Parameter localeCode: The code for the locale you would like to specify.
    /// - Returns: A newly created query with the results restricted to the specified locale.
    static func localizeResults(withLocaleCode localeCode: LocaleCode) -> Self {
        let query = Self()
        query.localizeResults(withLocaleCode: localeCode)
        return query
    }

    /// Instance method for further mutating a query which specifies the locale of the entries that should be returned
    /// If there's no content available for the requested locale the API will try the fallback locale of the requested locale.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/localization/retrieve-localized-entries>
    ///
    /// - Parameter localeCode: The code for the locale you would like to specify.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func localizeResults(withLocaleCode localeCode: LocaleCode) -> Self {
        self.parameters[QueryParameter.locale] = localeCode
        return self
    }

    /// Initializes a select operation query in which only the fields specified
    /// in the fieldNames property will be returned in the JSON response.
    /// The `"sys"` property is always requested by the SDK.
    /// Note that if you are using the select operator with an instance `QueryOn<EntryType>`
    /// that your model types must have optional types for properties that you are omitting in the response (by not including them in your selections array).
    /// If you are not using the `QueryOn` type while querying entries, make sure to specify the content type id.
    /// Example usage:
    ///
    /// ```
    /// let query = try! Query.select(fieldsNamed: ["bestFriend", "color", "name"]).where(contentTypeId: "cat")
    /// client.fetchMappedEntries(with: query).observable z { catsResponse in
    ///     let cats = catsResponse.items
    ///     // Do stuff with cats.
    /// }
    /// ```
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator>
    ///
    /// - Parameter fieldNames: An array of field names to include in the JSON response.
    /// - Returns: A newly initialized query selecting only certain fields to be returned in the response.
    /// - Throws: An error if selections go more than 1 level deep within the fields container ("bestFriend.sys" is not valid),
    ///           or if more than 99 properties are selected.
    static func select(fieldsNamed fieldNames: [FieldName]) throws -> Self {
        let query = Self()
        try query.select(fieldsNamed: fieldNames)
        return query
    }

    /// Instance method for select operation in which only the fields specified in the `fieldNames` parameter will be returned in the JSON response.
    /// The `"sys"` dictionary is always requested by the SDK.
    /// Note that if you are using the select operator with an instance `QueryOn<EntryType>`
    /// that you must make properties that you are ommitting in the response (by not including them in your selections array) optional properties.
    /// Example usage:
    ///
    /// ```
    /// let query = try! Query().select(fieldsNamed: ["bestFriend", "color", "name"])
    /// client.fetchEntries(with: query) { (result: Result<ArrayResponse<Cat>>) in
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
    /// - Parameter fieldNames: An array of field names to include in the JSON response.
    /// - Returns: A reference to the receiving query to enable chaining.
    /// - Throws: An error if selections go more than 1 level deep within the fields container ("bestFriend.sys" is not valid),
    ///           or if more than 99 properties are selected.
    @discardableResult
    func select(fieldsNamed fieldNames: [FieldName]) throws -> Self {

        guard fieldNames.count <= Int(QueryConstants.maxSelectedProperties) else { throw QueryError.maxSelectionLimitExceeded }

        let keyPaths = fieldNames.map { "fields.\($0)" }
        try ResourceQuery.validate(selectedKeyPaths: keyPaths)

        let validSelections = Query.addSysIfNeeded(to: keyPaths).joined(separator: ",")

        let parameters = self.parameters + [QueryParameter.select: validSelections]
        self.parameters = parameters
        return self
    }
}

/// The base abstract type for querying Contentful entries. The contained operations in the default implementation
/// of this protocol can only be used when querying against the `/entries/ endpoint of the Content Delivery and Content Preview APIs.
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
public protocol EntryQuery: AbstractResourceQuery {}
public extension EntryQuery {

    /// Initializes a new query specifying the `content_type` parameter to narrow the results to
    /// entries that have that content type identifier.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
    ///
    /// - Parameter contentTypeId: The identifier of the content type which the query will be performed on.
    /// - Returns: A new initialized Query narrowing the results to a specific content type.
    static func `where`(contentTypeId: ContentTypeId) -> Self {
        let query = Self()
        query.where(contentTypeId: contentTypeId)
        return query
    }

    /// Appends the `content_type` parameter to narrow the results to entries that have that content type identifier.
    ///
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
    ///
    /// - Parameter contentTypeId: The identifier of the content type which the query will be performed on.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(contentTypeId: ContentTypeId) -> Self {
        self.parameters[QueryParameter.contentType] = contentTypeId
        return self
    }

    /// Initialize a query to do a ["Search on References"](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references)
    /// which enables searching for entries based on value's for members of referenced entries.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = Query.where(linkAtFieldNamed: "bestFriend",
    ///                         onSourceContentTypeWithId: "cat",
    ///                         hasValueAtKeyPath: "fields.name",
    ///                         withTargetContentTypeId: "cat",
    ///                         that: .matches("Happy Cat"))
    /// ```
    ///
    /// - Parameters:
    ///   - linkingFieldName: The field name which holds a reference to a link.
    ///   - sourceContentTypeId: The content type identifier of the link source.
    ///   - targetKeyPath:  The member path for the value you would like to search on for the link destination resource.
    ///   - targetContentTypeId:  The content type idenifier of the item(s) being linked to at the specified linking field name.
    ///   - operation: The `Query.Operation` used to match the value of at the target key path.
    /// - Returns: A newly initialized query for searching on references.
    static func `where`(linkAtFieldNamed linkingFieldName: String,
                               onSourceContentTypeWithId sourceContentTypeId: ContentTypeId,
                               hasValueAtKeyPath targetKeyPath: String,
                               withTargetContentTypeId targetContentTypeId: ContentTypeId,
                               that operation: Query.Operation) -> Self {
        let query = Self()
        query.where(linkAtFieldNamed: linkingFieldName,
                    onSourceContentTypeWithId: sourceContentTypeId,
                    hasValueAtKeyPath: targetKeyPath,
                    withTargetContentTypeId: targetContentTypeId,
                    that: operation)
        return query
    }

    /// Use this method to do a ["Search on References"](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references)
    /// which enables searching for entries based on value's for members of referenced entries.
    ///
    /// Example usage:
    ///
    /// - Parameters:
    ///   - linkingFieldName: The field name which holds a reference to a link.
    ///   - sourceContentTypeId: The content type identifier of the link source.
    ///   - targetKeyPath: The member path for the value you would like to search on for the link destination resource.
    ///   - targetContentTypeId: The content type idenifier of the item(s) being linked to at the specified linking field name.
    ///   - operation: The `Query.Operation` used to match the value of at the target key path.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(linkAtFieldNamed linkingFieldName: String,
                        onSourceContentTypeWithId sourceContentTypeId: ContentTypeId,
                        hasValueAtKeyPath targetKeyPath: String,
                        withTargetContentTypeId targetContentTypeId: ContentTypeId,
                        that operation: Query.Operation) -> Self {
        self.parameters[QueryParameter.contentType] = sourceContentTypeId
        self.parameters["fields.\(linkingFieldName).sys.contentType.sys.id"] = targetContentTypeId

        let filterParameterName = "fields.\(linkingFieldName).\(targetKeyPath)\(operation.string)"
        self.parameters[filterParameterName] = operation.values
        return self
    }

    /// Static method creating a query that requires that an specific field of an entry
    /// holds a reference to another specific entry.
    ///
    /// Example usage:
    ///
    /// ```
    /// let query = Query.where(linkAtFieldNamed: "bestFriend",
    /// onSourceContentTypeWithId: "cat",
    /// hasValueAtKeyPath: "fields.name",
    /// withTargetContentTypeId: "cat",
    /// that: .matches("Happy Cat"))
    /// ```
    ///
    /// - Parameters:
    ///   - linkingFieldName: The field name which holds a reference to a link.
    ///   - sourceContentTypeId: The content type identifier of the link source.
    ///   - targetId: The identifier of the entry or asset being linked to at the specified linking field.
    /// - Returns: A newly initialized query for searching on references.
    static func `where`(linkAtFieldNamed linkingFieldName: String,
                               onSourceContentTypeWithId sourceContentTypeId: ContentTypeId,
                               hasTargetId targetId: String) -> Self {
        let query = Self()
        query.where(linkAtFieldNamed: linkingFieldName,
                    onSourceContentTypeWithId: sourceContentTypeId,
                    hasTargetId: targetId)
        return query
    }

    /// Instance method creating a query that requires that an specific field of an entry
    /// holds a reference to another specific entry.
    ///
    /// Example usage:
    ///
    /// - Parameters:
    ///   - linkingFieldName: The field name which holds a reference to a link.
    ///   - sourceContentTypeId: The content type identifier of the link source.
    ///   - targetId: The identifier of the entry or asset being linked to at the specified linking field.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(linkAtFieldNamed linkingFieldName: String,
                        onSourceContentTypeWithId sourceContentTypeId: ContentTypeId,
                        hasTargetId targetId: String) -> Self {
        self.parameters[QueryParameter.contentType] = sourceContentTypeId
        self.parameters["fields.\(linkingFieldName).sys.id"] = targetId

        return self
    }

    /// Static method for creating a query that will search for entries that have a field linking to
    /// another entry with a specific id.
    ///
    /// - Parameter entryId: The identifier of the entry which you want to find incoming links for.
    /// - Returns: A newly initialized query which will search for incoming links on a specific entry.
    static func `where`(linksToEntryWithId entryId: String) -> Self {
        let query = Self()
        query.where(linksToEntryWithId: entryId)
        return query
    }

    /// Instance method for creating a query that will search for entries that have a field linking to
    /// another entry with a specific id.
    ///
    /// - Parameter entryId: The identifier of the entry which you want to find incoming links for.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(linksToEntryWithId entryId: String) -> Self {
        self.parameters[QueryParameter.linksToEntry] = entryId
        return self
    }

    /// Static method for creating a query that will search for entries that have a field linking to
    /// an asset with a specific id.
    ///
    /// - Parameter assetId: The identifier of the asset which you want to find incoming links for
    /// - Returns:  A newly initialized query which will search for incoming links on a specific asset.
    static func `where`(linksToAssetWithId assetId: String) -> Self {
        let query = Self()
        query.where(linksToAssetWithId: assetId)
        return query
    }

    /// Static method for creating a query that will search for entries that have a field linking to
    /// an asset with a specific id.
    ///
    /// - Parameter assetId: The identifier of the asset which you want to find incoming links for.
    /// - Returns: A reference to the receiving query to enable chaining.
    @discardableResult
    func `where`(linksToAssetWithId assetId: String) -> Self {
        self.parameters[QueryParameter.linksToAsset] = assetId
        return self
    }
}

/// A concrete implementation of AbstractResourceQuery which serves as the base class for both EntryQuery and AssetQuery.
public class ResourceQuery: AbstractResourceQuery {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initalizer for Query.
    public required init() {
        self.parameters = [String: String]()
    }

    // MARK: Query.Private

    internal init(parameters: [String: String] = [:]) {
        self.parameters = parameters
    }

    fileprivate static func validate(selectedKeyPaths: [String]) throws {
        for fieldKeyPath in selectedKeyPaths {
            guard fieldKeyPath.isValidSelection() else {
                throw QueryError.invalidSelection(fieldKeyPath: fieldKeyPath)
            }
        }
    }

    fileprivate static func addSysIfNeeded(to selectedFieldNames: [String]) -> [String] {
        // Mutable copy.
        var completeSelections = selectedFieldNames
        if !completeSelections.contains("sys") {
            completeSelections.append("sys")
        }
        return completeSelections
    }
}

internal extension String {

    func isValidSelection() -> Bool {
        if split(separator: ".", maxSplits: 3, omittingEmptySubsequences: false).count > 2 {
            return false
        }
        return true
    }
}
