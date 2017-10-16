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
public struct QueryParameter {

    public static let contentType      = "content_type"
    public static let select           = "select"
    public static let order            = "order"
    public static let limit            = "limit"
    public static let skip             = "skip"
    public static let include          = "include"
    public static let locale           = "locale"
    public static let mimetypeGroup    = "mimetype_group"
    public static let fullTextSearch   = "query"
}

/**
 A small structure to create parametes used for ordering the responses when querying and endpoint
 that returns a colleciton of resources. 
 See: `ChainableQuery(orderBy orderParameters: OrderParameter...)`
 */
public class Ordering {

    public init(_ propertyName: String, inReverse: Bool = false) {
        self.reverse = inReverse
        self.propertyName = propertyName
    }

    public convenience init(sys: Sys.CodingKeys, inReverse: Bool = false) {
        self.init("sys.\(sys.stringValue)", inReverse: inReverse)
    }

    public convenience init(field: CodingKey, inReverse: Bool = false) {
        self.init("fields.\(field.stringValue)", inReverse: inReverse)
    }

    public let propertyName: String
    public let reverse: Bool
}


public class Ordered<EntryType>: Ordering where EntryType: EntryQueryable {

    public init(field: EntryType.Fields, inReverse: Bool = false) {
        super.init("fields.\(field.stringValue)", inReverse: inReverse)
    }
}

private struct QueryConstants {
    fileprivate static let maxLimit: UInt               = 1000
    fileprivate static let maxSelectedProperties: UInt  = 99
    fileprivate static let maxIncludes: UInt            = 10
}

/// Use types that conform to QueryableRange to perform queries with the four Range operators
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges>
public protocol QueryableRange {

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

    public var stringValue: String {
        return self.iso8601String
    }
}

/**
 Small struct to store location coordinates. This is used in preferences over CoreLocation types to avoid
 extra linking requirements for the SDK.
 */
public struct Location: Decodable {

    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        latitude        = try container.decode(Double.self, forKey: .latitude)
        longitude       = try container.decode(Double.self, forKey: .longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
    }
}

/// Use bounding boxes or bounding circles to perform queries on location-enabled content.
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/locations-in-a-bounding-object>
public enum Bounds {
    case box(bottomLeft: Location, topRight: Location)
    case circle(center: Location, radius: Double)
}

/// All the possible MIME types that are supported by Contentful. \
//  Developer note: Cases in String backed Swift enums have a raw value equal to the case name.
//  i.e. MimetypeGroup.attachement.rawValue = "attachment"
public enum MimetypeGroup: String {
    case attachment
    case plaintext
    case image
    case audio
    case video
    case richtext
    case presentation
    case spreadsheet
    case pdfdocument
    case archive
    case code
    case markup
}

public protocol AbstractQuery: class {

    // Unfortunately (compiler forced) required designated initializer so that default implementation of AbstractQuery
    // can guarantee that an object is constructed before doing additional mutations in convenience initializers.
    init()

    /// The parameters dictionary that are converted to `URLComponents` on the HTTP URL. Useful for debugging.
    var parameters: [String: String] { get set }
}

public extension AbstractQuery {

    /**
     Convenience intializer for creating a Query with a Query.Operation. See concrete types Query, FilterQuery, AssetQuery, and QueryOn
     for more information and example usage.

     - Parameter name: The name of the property you are performing the Query.Operation against. For instance,
                       `"sys.id"` or `"fields.yourFieldName"`
     - Parameter operation: the Query.Operation
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.


     */
    public static func `where`(valueAtKeyPath keyPath: String, _ operation: Query.Operation, locale: LocaleCode? = nil) -> Self {
        let parameter = keyPath + operation.string

        let query = Self()
        query.parameters[parameter] = operation.values
        query.setLocaleWithCode(locale)

        return query
    }

    internal func setLocaleWithCode(_ localeCode: LocaleCode?) {
        guard let localeCode = localeCode else { return }
        parameters[QueryParameter.locale] = localeCode
    }

    fileprivate init(parameters: [String: String], locale: String?) {
        self.init()
        self.parameters = parameters
        self.setLocaleWithCode(locale)
    }
}

/// Protocol which enables concrete query implementations to be 'chained' together so that results
/// can be filtered by more than one Query.Operation or other query. Protocol extensions give default implementation
/// so that all concrete types, `Query`, `AssetQuery`, `FilterQuery`, and `QueryOn<EntryType>`, can use the same implementation.
public protocol ChainableQuery: AbstractQuery {}
public extension ChainableQuery {

    /**
     Instance method for appending more Query.Operation's to further filter results on the API. Example usage:

     ```
     let query = Query(contentTypeId: "cat").where("fields.color", .doesNotEqual("gray"))

     // Mutate the query further.
     query.where("fields.lives", .equals("9"))
     ```

     - Parameter name: The name of the property you are performing the Query.Operation against. For instance,
     `"sys.id" or `"fields.yourFieldName"`
     - Parameter operation: the Query.Operation
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
     set on the `Client` instance is used.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func `where`(valueAtKeyPath keyPath: String, _ operation: Query.Operation, locale: LocaleCode? = nil) -> Self {

        // Create parameter for this query operation.
        let parameter = keyPath + operation.string
        self.parameters[parameter] = operation.values
        self.setLocaleWithCode(locale)
        return self
    }

    /**
     Convenience initializer to specify the level of includes to be resolved in the JSON response. The maximum permitted
     level of includes at the API level is 10, so the SDK will throw an error before the network request is made if the value is too high.
     To omit all linked items, specify an include level of 0.
     
     - Parameter includesLevel: An unsigned integer specifying the level of includes to be resolved.
     - Throws: A `QueryError` if the level of includes specified is greater than 10.
     
     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/links/retrieval-of-linked-items>
     */
    public static func include(_ includesLevel: UInt) -> Self {
        let query = Self()
        query.include(includesLevel)
        return query
    }

    /**
     Specify the level of includes to be resolved in the JSON response. The maximum permitted
     level of includes at the API level is 10, so the SDK will throw an error before the network request is made if the value is too high.
     To omit all linked items, specify an include level of 0.

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/links/retrieval-of-linked-items>
     
     - Parameter includesLevel: An unsigned integer specifying the level of includes to be resolved.

     */
    // TODO: Document that kept at ceiling
    @discardableResult public func include(_ includesLevel: UInt) -> Self {
        let includes = min(includesLevel, QueryConstants.maxIncludes)
        self.parameters[QueryParameter.include] = String(includes)
        return self
    }

    /**
     Convenience initializer for a ordering responses by the values at the specified field. Field types that can be
     specified are Strings, Numbers, or Booleans.

     Example usage:

     ```
     let query = try! Query(orderBy: OrderParameter("sys.createdAt"))

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order>
     and: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order-with-multiple-parameters>
     - Parameter propertyName: One or more properties on the Resource by which the results will be ordered.
     - Parameter reverse: An Bool specifying if the returned order should be reversed or not. Defaults to `false`.
     - Throws: Will throw an error if property names are not prefixed with either `"sys."` or `"fields."`.
     */
    public static func order(by order: Ordering...) throws -> Self {
        let query = Self()
        try query.order(by: order)
        return query
    }

    /**
     Convenience initializer for a limiting responses to a certain number of values. Use in conjunction with the `skip` method
     to paginate responses.

     Example usage:

     ```
     let query = try! Query(limitResultsTo: 10)

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     - Parameter numberOfResults: The number of results the response will be limited to.
     */
    public static func limit(to numberOfResults: UInt) -> Self {
        let query = Self()
        query.limit(to: numberOfResults)
        return query
    }

    /**
     Convenience initializer for a skipping the first `n` items in a response.
     Use in conjunction with the `limit` method to paginate responses.

     Example usage:

     ```
     let query = try! Query(skipTheFirst: 9)

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     - Parameter numberOfResults: The number of results that will be skipped in the query.
     */
    public static func skip(theFirst numberOfResults: UInt) -> Self {
        let query = Self()
        query.skip(theFirst: numberOfResults)
        return query
    }

    /**
     Instance method for ordering responses by the values at the specified field. Field types that can be
     specified are Strings, Numbers, or Booleans.

     Example usage:

     ```
     let query = try! Query().order(by: OrderParameter("sys.createdAt"))

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order>
     and: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/order-with-multiple-parameters>
     - Parameter propertyName: One or more properties on the Resource by which the results will be ordered.
     - Parameter reverse: An Bool specifying if the returned order should be reversed or not. Defaults to `false`.
     - Throws: Will throw an error if property names are not prefixed with either `"sys."` or `"fields."`.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func order(by order: Ordering...) throws -> Self {
        return try self.order(by: order)
    }

    /**
     Instance method for further mutating a query to limit responses to a certain number of values. Use in conjunction with the `skip` method
     to paginate responses.

     Example usage:

     ```
     let query = try! Query().limitResults(to: 10)

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     - Parameter numberOfResults: The number of results the response will be limited to.
     - Throws: A QueryError if the number of results specified is greater than 1000.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func limit(to numberOfResults: UInt) -> Self {
        let limit = min(numberOfResults, QueryConstants.maxLimit)

        self.parameters[QueryParameter.limit] = String(limit)
        return self
    }

    /**
     Intance method for further mutating a query to skip the first `n` items in a response.
     Use in conjunction with the `limit` method to paginate responses.

     Example usage:

     ```
     let query = try! Query().skip(theFirst: 10)

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```
     - Parameter numberOfResults: The number of results that will be skipped in the query.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func skip(theFirst numberOfResults: UInt) -> Self {
        self.parameters[QueryParameter.skip] = String(numberOfResults)
        return self
    }


    // MARK: Full-text search

    /**
     Convenience initializer for querying entries or assets in which all text and symbol fields contain
     the specified, case-insensitive text parameter.

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/full-text-search>
     - Parameter text: The text string to match against.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.
     - Throws: A QueryError if the text being searched for is 1 character in length or less.
     */
    public static func searching(for text: String, locale: LocaleCode? = nil) throws -> Self {
        let query = Self()
        try query.searching(for: text, locale: locale)
        return query
    }

    /**
     Instance method for appending a full-text search query to an existing query. Returned results will contain
     either entries or assets in which all text and symbol fields contain the specified, case-insensitive text parameter.

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/full-text-search>
     - Parameter text: The text string to match against.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
     set on the `Client` instance is used.
     - Throws: A QueryError if the text being searched for is 1 character in length or less.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func searching(for text: String, locale: LocaleCode? = nil) throws -> Self {
        guard text.characters.count > 1 else { throw QueryError.textSearchTooShort }
        self.parameters[QueryParameter.fullTextSearch] = text
        self.setLocaleWithCode(locale)
        return self
    }

    // MARK: ChainableQuery.Private

    // Helper to workaround Swift bug/issue: Despite the fact that Variadic's can be passed into
    // to functions expecting an `Array`, instances of `Array`
    // cannot be passed into a function expecting a variadic parameter.
    @discardableResult private func order(by order: [Ordering]) throws -> Self {
        let propertyNames = order.map { return $0.propertyName }

        // Validate
        for name in propertyNames {
            if name.hasPrefix("fields.") == false && name.hasPrefix("sys.") == false {
                throw QueryError.invalidOrderProperty
            }
        }

        let namesWithReverseParameter = order.map { $0.reverse ? "-\($0.propertyName)" : $0.propertyName }
        let joinedPropertyNames = namesWithReverseParameter.joined(separator: ",")

        self.parameters[QueryParameter.order] = joinedPropertyNames
        return self
    }
}

public protocol ResourceQuery: ChainableQuery {}
public extension ResourceQuery {
    /**
     Convenience initializer for a select operation query in which only the fields specified
     in the fieldNames property will be returned in the JSON response.
     The `"sys"` dictionary is always requested by the SDK.
     Note that if you are using the select operator with an instance `QueryOn<EntryType>`
     that your model types must have optional types for properties that you are omitting in the response (by not including them in your selections array).
     If you are not using the `QueryOn` type while querying entries, make sure to specify the content type id.
     Example usage:

     ```
     let query = try! Query(selectFieldsNamed: ["fields.bestFriend", "fields.color", "fields.name"]).on(contentTypeWith: "cat")
     client.fetchMappedEntries(with: query).observable.then { catsResponse in
     let cats = catsResponse.items
     // Do stuff with cats.
     }
     ```

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator>
     - Parameter fieldNames: An array of field names to include in the JSON response.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
     set on the `Client` instance is used.
     - Throws: Will throw an error if property names are not prefixed with `"fields."`, if selections go more than 2 levels deep
     ("fields.bestFriend.sys" is not valid), or if more than 99 properties are selected.
     */
    public static func select(fieldsNamed fieldNames: [FieldName], locale: LocaleCode? = nil) throws -> Self {
        let query = Self()
        try query.select(fieldsNamed: fieldNames, locale: locale)
        return query
    }

    /**
     Instance method for select operation in which only the fields specified in the fieldNames property will be returned in the JSON response.
     The `"sys"` dictionary is always requested by the SDK.
     Note that if you are using the select operator with an instance `QueryOn<EntryType>`
     that you must make properties that you are ommitting in the response (by not including them in your selections array) optional properties.
     Example usage:

     ```
     let query = try! Query().select(fieldsNamed: ["fields.bestFriend", "fields.color", "fields.name"])
     client.fetchEntries(with: query).observable.then { catsResponse in
     let cats = catsResponse.items
     // Do stuff with cats.
     }
     ```

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/select-operator>
     - Parameter fieldNames: An array of field names to include in the JSON response.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
     set on the `Client` instance is used.
     - Throws: Will throw an error if property names are not prefixed with `"fields."`, if selections go more than 2 levels deep
     ("fields.bestFriend.sys" is not valid), or if more than 99 properties are selected.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func select(fieldsNamed fieldNames: [FieldName], locale: LocaleCode? = nil) throws -> Self {

        guard fieldNames.count <= Int(QueryConstants.maxSelectedProperties) else { throw QueryError.maxSelectionLimitExceeded }

        let keyPaths = fieldNames.map { "fields.\($0)" }
        try Query.validate(selectedKeyPaths: keyPaths)

        let validSelections = Query.addSysIfNeeded(to: keyPaths).joined(separator: ",")

        let parameters = self.parameters + [QueryParameter.select: validSelections]
        self.parameters = parameters
        self.setLocaleWithCode(locale)
        return self
    }
}

public protocol EntryQuery: ResourceQuery {}
public extension EntryQuery {
    /// Initialize a new query specifying the `content_type` parameter to narrow the results to
    /// entries that have that content type identifier.
    /// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
    public static func `where`(contentTypeId: ContentTypeId) -> Self {
        let query = Self()
        query.where(contentTypeId: contentTypeId)
        return query
    }

    /**
     Append the `content_type` parameter to narrow the results to entries that have that content type identifier.
     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters>
     - Parameter id: the identifier of the content type which the query will be performed on.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func `where`(contentTypeId: ContentTypeId) -> Self {
        self.parameters[QueryParameter.contentType] = contentTypeId
        return self
    }

    /**
     Initialize a query to do a ["Search on References"](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references)
     which enables searching for entries based on value's for members of referenced entries.
     Example usage:
     ```
     let query = Query(whereLinkAtFieldNamed: "bestFriend",
     onSourceContentTypeWithId: "cat",
     hasValueAt: "fields.name",
     withTargetContentTypeId: "cat",
     that: .matches("Happy Cat"))
     ```
     - Parameter linkingFieldName: The field name which holds a reference to a link.
     - Parameter sourceContentTypeId: The content type identifier of the link source.
     - Parameter targetKeyPath: The member path for the value you would like to search on for the link destination resource.
     - Parameter targetContentTypeId: The content type idenifier of the item(s) being linked to at the specified linking field name.
     - Parameter operation: The `Query.Operation` used to match the value of at the target key path.
     */
    public static func `where`(linkAtFieldNamed linkingFieldName: String,
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

    /**
     Use this method to do a ["Search on References"](https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references)
     which enables searching for entries based on value's for members of referenced entries.
     Example usage:

     - Parameter linkingFieldName: The field name which holds a reference to a link.
     - Parameter sourceContentTypeId: The content type identifier of the link source.
     - Parameter targetKeyPath: The member path for the value you would like to search on for the link destination resource.
     - Parameter targetContentTypeId: The content type idenifier of the item(s) being linked to at the specified linking field name.
     - Parameter operation: The `Query.Operation` used to match the value of at the target key path.
     - Returns: A reference to the receiving query to enable chaining.
     */
    @discardableResult public func `where`(linkAtFieldNamed linkingFieldName: String,
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
}

/// A concrete implementation of ChainableQuery which can be used to make queries on either `/assets/`
/// or `/entries`. All methods from ChainableQuery are available.
public class Query: EntryQuery {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initalizer for Query.
    public required init() {
        self.parameters = [String: String]()
    }


    // MARK: Query.Private

    fileprivate init(parameters: [String: String] = [:], locale: String? = nil) {
        self.parameters = parameters
        self.setLocaleWithCode(locale)
    }

    fileprivate static func validate(selectedKeyPaths: [String]) throws {
        for fieldKeyPath in selectedKeyPaths {
            guard fieldKeyPath.isValidSelection() else {
                throw QueryError.invalidSelection(fieldKeyPath: fieldKeyPath)
            }
        }
    }

    fileprivate static func addSysIfNeeded(to selectedFieldNames: [String]) -> [String] {
        var completeSelections = selectedFieldNames
        if !completeSelections.contains("sys") {
            completeSelections.append("sys")
        }
        return completeSelections
    }

    /**
     Property-value query operations used for matching patterns on either "sys" or "fields" properties of `Asset`s and `Entry`s.
     Each operation specifies a property name on the left-hand side, with a value to match on the right.
     For instance, using the doesNotEqual operation in an a concrete Query like:

     ```
     Query(where:"fields.name", .doesNotEqual("Happy Cat"))
     ```

     would append the following to the http URL:

     ```
     "fields.name[ne]=Happy%20Cat"
     ```

     Refer to the documentation for the various Query classes for more information.
     */
    public enum Operation {

        case equals(String)
        case doesNotEqual(String)
        case hasAll([String])
        case includes([String])
        case excludes([String])
        case exists(Bool)

        /// Full text search on a field.
        case matches(String)

        /// MARK: Ranges
        case isLessThan(QueryableRange)
        case isLessThanOrEqualTo(QueryableRange)
        case isGreaterThan(QueryableRange)
        case isGreaterThanOrEqualTo(QueryableRange)
        case isBefore(QueryableRange)
        case isAfter(QueryableRange)

        /// Proximity searches.
        case isNear(Location)
        case isWithin(Bounds)

        internal var string: String {
            switch self {
            case .equals:                                       return ""
            case .doesNotEqual:                                 return "[ne]"
            case .hasAll:                                       return "[all]"
            case .includes:                                     return "[in]"
            case .excludes:                                     return "[nin]"
            case .exists:                                       return "[exists]"
            case .matches:                                      return "[match]"

            case .isLessThan:                                   return "[lt]"
            case .isLessThanOrEqualTo:                          return "[lte]"
            case .isGreaterThan:                                return "[gt]"
            case .isGreaterThanOrEqualTo:                       return "[gte]"
            case .isBefore:                                     return "[lte]"
            case .isAfter:                                      return "[gte]"

            case .isNear:                                       return "[near]"
            case .isWithin:                                     return "[within]"
            }
        }

        internal var values: String {
            switch self {
            case .equals(let value):                            return value
            case .doesNotEqual(let value):                      return value
            case .hasAll(let values):                           return values.joined(separator: ",")
            case .includes(let values):                         return values.joined(separator: ",")
            case .excludes(let values):                         return values.joined(separator: ",")
            case .exists(let value):                            return String(value)
            case .matches(let value):                           return value

            case .isLessThan(let queryableRange):               return queryableRange.stringValue
            case .isLessThanOrEqualTo(let queryableRange):      return queryableRange.stringValue
            case .isGreaterThan(let queryableRange):            return queryableRange.stringValue
            case .isGreaterThanOrEqualTo(let queryableRange):   return queryableRange.stringValue
            case .isBefore(let queryableRange):                 return queryableRange.stringValue
            case .isAfter(let queryableRange):                  return queryableRange.stringValue

            case .isNear(let coordinates):                      return "\(coordinates.latitude),\(coordinates.longitude)"
            case .isWithin(let bounds):                         return string(for: bounds)
            }
        }

        private func string(for bounds: Bounds) -> String {
            switch bounds {
            case .box(let bottomLeft, let topRight):
                return "\(bottomLeft.latitude),\(bottomLeft.longitude),\(topRight.latitude),\(topRight.longitude)"

            case .circle(let center, let radius):
                return "\(center.latitude),\(center.longitude),\(radius)"
            }
        }
    }
}

internal extension String {

    func isValidSelection() -> Bool {
        if characters.split(separator: ".", maxSplits: 3, omittingEmptySubsequences: false).count > 2 {
            return false
        }
        return true
    }
}
