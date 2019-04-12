//
//  QueryOperation.swift
//  Contentful
//
//  Created by JP Wright on 16.10.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public extension Query {

    /// Property-value query operations used for matching patterns on either "sys" or "fields" properties of assets and entries.
    /// Each operation specifies a property name on the left-hand side, with a value to match on the right.
    /// For instance, using the `.doesNotEqual` operation in an a concrete `Query` like:
    ///
    /// ```
    /// Query(where:"fields.name", .doesNotEqual("Happy Cat"))
    /// ```
    ///
    /// would append the following to the http URL:
    ///
    /// ```
    /// "fields.name[ne]=Happy%20Cat"
    /// ```
    ///
    /// Refer to the documentation for the various Query classes for more information.
    enum Operation {

        /// The equality operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/equality-operator>
        case equals(String)
        /// The inequality operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/inequality-operator>
        case doesNotEqual(String)
        /// Query by matching all of the values in the set: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/array-with-multiple-values>
        case hasAll([String])
        /// The inclusion operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/inclusion>
        case includes([String])
        /// The exclusion operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/exclusion>
        case excludes([String])
        /// The existence operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/existence>
        case exists(Bool)

        /// Full text search on a field.
        case matches(String)

        /// MARK: Ranges

        /// Less-than operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges>
        case isLessThan(QueryableRange)
        /// Less-than-or-equal-to operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges>
        case isLessThanOrEqualTo(QueryableRange)
        /// Greater-than operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges>
        case isGreaterThan(QueryableRange)
        /// Greater-than-or-equal-to operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges>
        case isGreaterThanOrEqualTo(QueryableRange)
        /// Equivalent to the less-than operator: https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges
        case isBefore(QueryableRange)
        /// Equivalent to the greater-than operator: https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/ranges
        case isAfter(QueryableRange)

        /// Location proximity search: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/location-proximity-search
        case isNear(Location)
        /// Location within bounding box operator: <https://www.contentful.com/developers/docs/references/content-delivery-api/#/reference/search-parameters/locations-in-a-bounding-object>
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
