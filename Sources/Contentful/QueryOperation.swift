//
//  QueryOperation.swift
//  Contentful
//
//  Created by JP Wright on 16.10.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public extension Query {
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
