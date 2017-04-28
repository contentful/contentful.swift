//
//  Query.swift
//  Contentful
//
//  Created by JP Wright on 06/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar
import CoreLocation

/// The available URL parameter names for queries; used internally by the various `Contentful.Query` types.
/// Use these static variables to avoid making typos when constructing queries. It is recommended to take
/// advantage of `Client` "fetch" methods that take `Query` types instead of constructing query dictionaries on your own.
public struct QueryParameter {

    static let contentType      = "content_type"
    static let select           = "select"
    static let order            = "order"
    static let limit            = "limit"
    static let skip             = "skip"
    static let include          = "include"
    static let locale           = "locale"
    static let mimetypeGroup    = "mimetype_group"
    static let fullTextSearch   = "query"
}

/**
 A small structure to create parametes used for ordering the responses when querying and endpoint
 that returns a colleciton of resources. 
 See: `ChainableQuery(orderedUsing orderParameters: OrderParameter...)`
 */
public struct OrderParameter {

    public init(_ propertyName: String, inReverse: Bool = false) {
        self.reverse = inReverse
        self.propertyName = propertyName
    }

    let propertyName: String
    let reverse: Bool
}

fileprivate struct QueryConstants {
    static let maxLimit: UInt               = 1000
    static let maxSelectedProperties: UInt  = 99
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
        return self.toISO8601GMTString()!
    }
}

/// Use bounding boxes or bounding circles to perform queries on location-enabled content.
/// See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/locations-in-a-bounding-object>
public enum Bounds {
    case box(bottomLeft: CLLocationCoordinate2D, topRight: CLLocationCoordinate2D)
    case circle(center: CLLocationCoordinate2D, radius: Double)
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
public enum QueryOperation {

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

    /// Proximity searches.
    case isNear(CLLocationCoordinate2D)
    case isWithin(Bounds)

    fileprivate var string: String {
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

        case .isNear:                                       return "[near]"
        case .isWithin:                                     return "[within]"
        }
    }

    fileprivate var values: String {
        switch self {
        case .equals(let value):                            return value
        case .doesNotEqual(let value):                      return value
        case .hasAll(let values):                           return values.joined(separator: ",")
        case .includes(let values):                         return values.joined(separator: ",")
        case .excludes(let values):                         return values.joined(separator: ",")
        case .exists(let value):                            return value ? "true" : "false"
        case .matches(let value):                           return value

        case .isLessThan(let queryableRange):               return queryableRange.stringValue
        case .isLessThanOrEqualTo(let queryableRange):      return queryableRange.stringValue
        case .isGreaterThan(let queryableRange):            return queryableRange.stringValue
        case .isGreaterThanOrEqualTo(let queryableRange):   return queryableRange.stringValue

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


public protocol AbstractQuery: class {

    // Unfortunately (compiler forced) required designated initializer so that default implementation of AbstractQuery
    // can guarantee that an object is constructed before doing additional mutations in convenience initializers.
    init()

    /// The parameters dictionary that are converted to `URLComponents` on the HTTP URL. Useful for debugging.
    var parameters: [String: String] { get set }
}

public extension AbstractQuery {

    /**
     Convenience intializer for creating a Query with a QueryOperation. See concrete types Query, FilterQuery, AssetQuery, and QueryOn
     for more information and example usage.

     - Parameter name: The name of the property you are performing the QueryOperation against. For instance,
                       `"sys.id"` or `"fields.yourFieldName"`
     - Parameter operation: the QueryOperation
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.

     
     */
    public init(where name: String, _ operation: QueryOperation, for locale: String? = nil) {
        self.init()
        self.parameters = [String: String]()
        self.addFilter(where: name, operation, for: locale)
    }

    fileprivate func addFilter(where name: String, _ operation: QueryOperation, for locale: String? = nil) {

        // Create parameter for this query operation.
        let parameter = name + operation.string
        parameters[parameter] = operation.values
        set(locale: locale)
    }

    fileprivate func set(locale: String?) {
        guard let locale = locale else { return }
        parameters[QueryParameter.locale] = locale
    }

    fileprivate init(parameters: [String: String], locale: String?) {
        self.init()
        self.parameters = parameters

        if let locale = locale {
            self.parameters[QueryParameter.locale] = locale
        }
    }
}

/// Protocol which enables concrete query implementations to be 'chained' together so that results
/// can be filtered by more than one QueryOperation or other query. Protocol extensions give default implementation
/// so that all concrete types, `Query`, `AssetQuery`, `FilterQuery`, and `QueryOn<EntryType>`, can use the same implementation.
public protocol ChainableQuery: AbstractQuery {}
public extension ChainableQuery {

    /**
     Convenience initializer for a select operation query in which only the fields specified 
     in the fieldNames property will be returned in the JSON response.
     The `"sys"` dictionary is always requested by the SDK. 
     Note that if you are using the select operator with an instance `QueryOn<EntryType>`
     that you must make properties that you are ommitting in the response (by not including them in your selections array) optional properties.
     Example usage:
     
     ```
     let query = try! QueryOn<Cat>(selectingFieldsNamed: ["fields.bestFriend", "fields.color", "fields.name"])
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
    public init(selectingFieldsNamed fieldNames: [String], for locale: String? = nil) throws {
        self.init()
        try self.select(fieldsNamed: fieldNames, locale: locale)
    }

    /**
     Convenience initializer for a ordering responses by the values at the specified field. Field types that can be
     specified are Strings, Numbers, or Booleans.

     Example usage:

     ```
     let query = try! Query(orderedUsing: OrderParameter("sys.createdAt"))

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
    public init(orderedUsing orderParameters: OrderParameter...) throws {
        self.init()
        try self.order(using: orderParameters)
    }

    /**
     Convenience initializer for a limiting responses to a certain number of values. Use in conjunction with the `skip` method
     to paginate responses.

     Example usage:

     ```
     let query = try! Query(orderedBy: "sys.createdAt")

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     - Parameter numberOfResults: The number of results the response will be limited to.
     */
    public init(limitingResultsTo numberOfResults: UInt) throws {
        guard numberOfResults <= QueryConstants.maxLimit else { throw QueryError.maximumLimitExceeded }

        let parameters = [QueryParameter.limit: String(numberOfResults)]
        self.init(parameters: parameters, locale: nil)
    }

    /**
     Convenience initializer for a skipping the first `n` items in a response.
     Use in conjunction with the `limit` method to paginate responses.

     Example usage:

     ```
     let query = try! Query(skippingTheFirst: 9)

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     - Parameter numberOfResults: The number of results that will be skipped in the query.
     */
    public init(skippingTheFirst numberOfResults: UInt) {
        let parameters = [QueryParameter.skip: String(numberOfResults)]
        self.init(parameters: parameters, locale: nil)
    }

    /**
     Instance method for select operation in which only the fields specified in the fieldNames property will be returned in the JSON response.
     The `"sys"` dictionary is always requested by the SDK.
     Note that if you are using the select operator with an instance `QueryOn<EntryType>`
     that you must make properties that you are ommitting in the response (by not including them in your selections array) optional properties.
     Example usage:

     ```
     let query = try! QueryOn<Cat>()
     query.select(fieldsNamed: ["fields.bestFriend", "fields.color", "fields.name"])
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
     */
    func select(fieldsNamed fieldNames: [String], locale: String? = nil) throws {

        guard fieldNames.count <= Int(QueryConstants.maxSelectedProperties) else { throw QueryError.maxSelectionLimitExceeded }

        try Query.validate(selectedKeyPaths: fieldNames)

        let validSelections = Query.addSysIfNeeded(to: fieldNames).joined(separator: ",")

        let parameters = self.parameters + [QueryParameter.select: validSelections]
        self.parameters = parameters
    }

    /**
     Instance method for ordering responses by the values at the specified field. Field types that can be
     specified are Strings, Numbers, or Booleans.

     Example usage:

     ```
     let query = try! Query(orderedUsing: OrderParameter("sys.createdAt"))

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
    public func order(using orderParameters: OrderParameter...) throws {
        try order(using: orderParameters)
    }

    /**
     Instance method for further mutating a query to limit responses to a certain number of values. Use in conjunction with the `skip` method
     to paginate responses.

     Example usage:

     ```
     let query = try! Query(orderedBy: "sys.createdAt")

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     - Parameter numberOfResults: The number of results the response will be limited to.
     */
    public func limit(to numberOfResults: UInt) throws {
        guard numberOfResults <= QueryConstants.maxLimit else { throw QueryError.maximumLimitExceeded }

        self.parameters[QueryParameter.limit] = String(numberOfResults)
    }

    /**
     Intance method for further mutating a query to skip the first `n` items in a response.
     Use in conjunction with the `limit` method to paginate responses.

     Example usage:

     ```
     let query = try! Query(skippingTheFirst: 9)

     client.fetchEntries(with: query).observable.then { entriesResponse in
        let entries = entriesResponse.items
        // Do stuff with entries.
     }
     ```

     - Parameter numberOfResults: The number of results that will be skipped in the query.
     */
    public func skip(theFirst numberOfResults: UInt) {
        self.parameters[QueryParameter.skip] = String(numberOfResults)
    }


    // MARK: Full-text search

    /**
     Convenience initializer for querying entries or assets in which all text and symbol fields contain
     the specified, case-insensitive text parameter.

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/full-text-search>
     - Parameter text: The text string to match against.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.
     */
    public init(searchingFor text: String, for locale: String? = nil) throws {
        guard text.characters.count > 1 else { throw QueryError.textSearchTooShort }
        let parameters = [QueryParameter.fullTextSearch: text]
        self.init(parameters: parameters, locale: locale)
    }

    /**
     Instance method for appending a full-text search query to an existing query. Returned results will contain
     either entries or assets in which all text and symbol fields contain the specified, case-insensitive text parameter.

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/full-text-search>
     - Parameter text: The text string to match against.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
     set on the `Client` instance is used.
     */
    public func search(for text: String) {
        self.parameters[QueryParameter.fullTextSearch] = text
    }

    // MARK: ChainableQuery.Private

    // Helper to workaround Swift bug/issue: Despite the fact that Variadic's can be passed into
    // to functions expecting an `Array`, instances of `Array`
    // cannot be passed into a function expecting a variadic parameter.
    private func order(using orderParameters: [OrderParameter]) throws {
        let propertyNames = orderParameters.map { return $0.propertyName }

        // Validate
        for name in propertyNames {
            if name.hasPrefix("fields.") == false && name.hasPrefix("sys.") == false {
                throw QueryError.invalidOrderProperty
            }
        }

        let namesWithReverseParameter = orderParameters.map { $0.reverse ? "-\($0.propertyName)" : $0.propertyName }
        let joinedPropertyNames = namesWithReverseParameter.joined(separator: ",")

        self.parameters[QueryParameter.order] = joinedPropertyNames
    }
}


/// A concrete implementation of ChainableQuery which can be used to make queries on either `/assets/`
/// or `/entries`. All methods from ChainableQuery are available.
public class Query: ChainableQuery {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initalizer for Query.
    public required init() {
        self.parameters = [String: String]()
    }

    // MARK: Query.Private

    fileprivate init(parameters: [String: String] = [:], locale: String? = nil) {
        self.parameters = parameters

        if let locale = locale {
            self.parameters[QueryParameter.locale] = locale
        }
    }

    fileprivate class func validate(selectedKeyPaths: [String]) throws {
        for fieldKeyPath in selectedKeyPaths {
            guard fieldKeyPath.isValidSelection() else {
                throw QueryError.invalidSelection(fieldKeyPath: fieldKeyPath)
            }
        }
    }

    fileprivate class func addSysIfNeeded(to selectedFieldNames: [String]) -> [String] {
        var completeSelections = selectedFieldNames
        if !completeSelections.contains("sys") {
            completeSelections.append("sys")
        }
        return completeSelections
    }
}

/// Queries on Asset types. All methods from Query, and therefore ChainableQuery, are inherited and available.
public final class AssetQuery: Query {
    /**
     Convenience intializer for creating an AssetQuery with the "mimetype_group" parameter specified. Example usage:

     ```
     let query = AssetQuery(whereMimetypeGroupIs: .image)
     client.fetchAssets(with: query).observable.then { assetsResponse in
        let assets = assetsResponse.items
        // Do stuff with assets.
     }
     ```

     - Parameter mimetypeGroup: The `mimetype_group` which all returned Assets will match.
     */
    public convenience init(whereMimetypeGroupIs mimetypeGroup: MimetypeGroup) {
        self.init()
        self.mimetypeGroup(is: mimetypeGroup)
    }

    /**
     Instance method for mutating the query further to specify the mimetype group when querying assets.

     - Parameter mimetypeGroup: The `mimetype_group` which all returned Assets will match.
     */
    public func mimetypeGroup(is mimetypeGroup: MimetypeGroup) {
        self.parameters[QueryParameter.mimetypeGroup] = mimetypeGroup.rawValue
    }
}

/** 
 An additional query to filter by the properties of linked objects when searching on references.
 See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
 and see the init<LinkType: EntryModellable>(whereLinkAt fieldNameForLink: String, matches filterQuery: FilterQuery<LinkType>? = nil) methods
 on QueryOn for example usage.
*/
public final class FilterQuery<EntryType>: AbstractQuery where EntryType: EntryModellable {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /**
     Convenience intializer for creating a QueryOn with a QueryOperation. Example usage:

     ```
     let filterQuery = FilterQuery<Cat>(where: "fields.name", .matches("Happy Cat"))
     let query = QueryOn<Cat>(whereLinkAt: "bestFriend", matches: filterQuery)
     ```

     - Parameter name: The name of the property you are performing the QueryOperation against. For instance,
                       `"sys.id"` or `"fields.yourFieldName"`
     - Parameter operation: the QueryOperation
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.
     */
    public convenience init(where name: String, _ operation: QueryOperation, for locale: String? = nil) {
        self.init()

        self.propertyName = name
        self.operation = operation
        self.addFilter(where: name, operation, for: locale)
    }

    /// Designated initializer for FilterQuery.
    public init() {
        self.parameters = [QueryParameter.contentType: EntryType.contentTypeId]
    }

    // MARK: FilterQuery<EntryType>.Private

    fileprivate var operation: QueryOperation!
    fileprivate var propertyName: String!
}

/**
 A concrete implementation of AbstractQuery which requires that a model class conforming to `EntryType`
 be passed in as a generic parameter. 
 
 The "content_type" parameter of the query will be set to the `contentTypeID`
 of your `EntryType` conforming model class. `QueryOn<EntryType>` are chainable so complex queries can be constructed.
 Operations that are only available when querying `Entry`s on specific content types (i.e. content_type must be set) 
 are available through this class.
 */
public final class QueryOn<EntryType>: ChainableQuery where EntryType: EntryModellable {

    /// The parameters dictionary that are converted to `URLComponents` (HTTP parameters/arguments) on the HTTP URL. Useful for debugging.
    public var parameters: [String: String] = [String: String]()

    /// Designated initializer for `QueryOn<EntryType>`.
    public init() {
        self.parameters = [QueryParameter.contentType: EntryType.contentTypeId]
    }

    /**
     Convenience intializer for creating a QueryOn with a QueryOperation. Example usage:

     ```
     let query = QueryOn<Cat>(where: "fields.color", .doesNotEqual("gray"))
     ```

     - Parameter name: The name of the property you are performing the QueryOperation against. For instance,
                       `"sys.id"` or `"fields.yourFieldName"`
     - Parameter operation: The QueryOperation.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.


     */
    public convenience init(where name: String, _ operation: QueryOperation, for locale: String? = nil) {
        self.init()
        self.addFilter(where: name, operation, for: locale)
    }

    /**
     Instance method for appending more QueryOperation's to further filter results on the API. Example usage:

     ```
     let query = QueryOn<Cat>(where: "fields.color", .doesNotEqual("gray"))

     // Mutate the query further.
     query.where("fields.lives", .equals("9"))
     ```

     - Parameter name: The name of the property you are performing the QueryOperation against. For instance,
                       `"sys.id" or `"fields.yourFieldName"`
     - Parameter operation: the QueryOperation
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.


     */
    public func `where`(_ name: String, _ operation: QueryOperation, for locale: String? = nil) {
        self.addFilter(where: name, operation, for: locale)
    }

    /**
     Convenience initalizer for performing searches where Linked objects at the specified linking field match the filtering query. 
     For instance, if you want to query all Entry's of type "cat" where cat's linked via the "bestFriend" field have names that match "Happy Cat"
     the code would look like the following:

     ```
     let filterQuery = FilterQuery<Cat>(where: "fields.name", .matches("Happy Cat"))
     let query = QueryOn<Cat>(whereLinkAt: "bestFriend", matches: filterQuery)
     client.fetchMappedEntries(with: query).observable.then { catsWithHappyCatAsBestFriendResponse in
        let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
        // Do stuff with catsWithHappyCatAsBestFriend
     }
     ```

     See: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/search-on-references>
     - Parameter fieldNameForLink: The name of the property which contains a link to another Entry.
     - Parameter filterQuery: The optional filter query applied to the linked objects which are being searched.
     - Parameter locale: An optional locale argument to return localized results. If unspecified, the locale originally
                         set on the `Client` instance is used.
     */
    public convenience init<LinkType>(whereLinkAt fieldNameForLink: String, matches filterQuery: FilterQuery<LinkType>? = nil,
                            for locale: String? = nil) where LinkType: EntryModellable {
        self.init()

        self.parameters["fields.\(fieldNameForLink).sys.contentType.sys.id"] = LinkType.contentTypeId

        // If propertyName isn't unrwrapped, the string isn't constructed correctly for some reason.
        if let filterQuery = filterQuery, let propertyName = filterQuery.propertyName {
            let filterParameterName = "fields.\(fieldNameForLink).\(propertyName)\(filterQuery.operation.string)"
            self.parameters[filterParameterName] = filterQuery.operation.values
        }
        self.set(locale: locale)
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
