//
//  Error.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Possible errors being thrown by the SDK
public enum SDKError: Error {
    /// Thrown when no valid client is available during sync
    case invalidClient()

    /**
     *  Thrown when receiving an invalid HTTP response
     *
     *  @param URLResponse? Optional URL response that has triggered the error
     */
    case invalidHTTPResponse(response: URLResponse?)

    /**
     *  Thrown when constructing an invalid URL
     *
     *  @param String The invalid URL string
     */
    case invalidURL(string: String)

    /// Thrown if the sync endpoint is called while being in preview mode
    case previewAPIDoesNotSupportSync()

    /**
     *  Thrown when receiving unparseable JSON responses
     *
     *  @param Data The data being parsed
     *  @param String The error which occured during parsing
     */
    case unparseableJSON(data: Data?, errorMessage: String)

    /// Thrown when no entry is found matching a specific Entry id
    case noEntryFoundFor(id: String)

    /// Thrown when the construction of a URL pointing to an underlying media file for an Asset is invalid.
    case invalidImageParameters(String)

    /// Thrown when a `Foundation.Data` object is unable to be transformed to a `UIImage` or an `NSImage` object.
    case unableToDecodeImageData

    /// Thrown when the SDK has issues mapping responses with the necessary locale information.
    case localeHandlingError(message: String)
}

/// Errors thrown for queries which have invalid construction.
public enum QueryError: Error, CustomDebugStringConvertible {

    public var debugDescription: String {
        return message
    }

    var message: String {
        switch self {
        case .invalidSelection(let fieldKeyPath):
            return "Selection for \(fieldKeyPath) is invalid. Make sure it has at most 1 '.' character in it."
        case .maxSelectionLimitExceeded:
            return "Can select at most 99 key paths when using the select operator on a content type."
        case .invalidOrderProperty:
            return "Either 'sys' or 'fields' properties must be specified. Prefix your propety name with 'fields.' or 'sys.'."
        case .textSearchTooShort:
            return "Full text search must have a string with more than 1 character."
        }
    }

    /// Thrown if the query string for a full-text search query only has less than 2 characters.
    case textSearchTooShort

    /// Thrown when attempting to order query results with a property that is not prefixed with "fields." or "sys.".
    case invalidOrderProperty

    /// Thrown when a selection for the `select` operator is constructed in a way that is invalid.
    case invalidSelection(fieldKeyPath: String)

    /// Thrown when over 99 properties have been selected. The CDA only supports 100 selections
    /// and the SDK always includes "sys" as one of them.
    case maxSelectionLimitExceeded
}


/// Information regarding an error received from Contentful's API.
public class APIError: Decodable, Error, CustomDebugStringConvertible {

    // Format the output for printing from the debug console
    public var debugDescription: String {
        let statusCodeString = "HTTP status code " + String(statusCode)
        let detailsStrings = details?.errors.flatMap({ $0.details }).joined(separator: "\n") ?? ""
        let debugDescription =
        """
        \(statusCodeString): \(message!)
        \(detailsStrings).
        Contentful Request ID: \(requestId!)
        """
        return debugDescription
    }

    /// System fields for the error.
    public struct Sys: Decodable {
        /// The identifier for the error.
        let id: String
        /// The type of the error.
        let type: String
    }

    public let sys: Sys

    /// Human readable error message.
    public let message: String!

    /// The identifier of the request, can be useful when making support requests.
    public let requestId: String!

    /// The HTTP status code.
    public var statusCode: Int!

    public let details: Details?

    public struct Details: Decodable {

        public let errors: [Details.Error]

        public struct Error: Decodable {
            public let name: String
            public let path: [String]
            public let details: String
        }
    }

    public var id: String? {
        return sys.id
    }

    public var type: String? {
        return sys.type
    }

    public required init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        sys             = try container.decode(Sys.self, forKey: .sys)
        message         = try container.decodeIfPresent(String.self, forKey: .message)
        requestId       = try container.decodeIfPresent(String.self, forKey: .requestId)
        details         = try container.decodeIfPresent(Details.self, forKey: .details)
    }

    /**
     * API Errors from the Contentful Delivery API are special cased for JSON deserialization:
     * Rather than throw an error and trigger a Swift error breakpoint in Xcode,
     * we use failable initializers so that consumers don't experience error breakpoints when
     * no error was returned from the API.
     */
    internal static func error(with decoder: JSONDecoder, data: Data, statusCode: Int) -> APIError? {
        if let error = try? decoder.decode(APIError.self, from: data) {
            // An error must have these things.
            guard error.message != nil && error.requestId != nil else {
                return nil
            }
            error.statusCode = statusCode
            return error
        }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case sys, message, requestId, details
    }
}

/**
 For requests that do hit the Contentful Delivery API enforces rate limits of 78 requests per second
 and 280800 requests per hour by default. Higher rate limits may apply depending on your current plan.
 */
public final class RateLimitError: APIError {
    /**
     An integer specifying the time before one of the two limits resets and another request 
     to the API will be accepted. If the client is rate limited per second, the header will return 1, 
     which means the next second. If the client is rate limited per hour, the next reset will be 
     determined like this: Every request which was made in the last hour gets counted in one of four
     15 minute buckets. Every time a request comes in, the API calculates how many seconds remain 
     until the sum of all bucket counts will be below the hourly limit. 
     See [the API Rate Limit docs](https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/api-rate-limits) 
     for more information.
     */
    public internal(set) var timeBeforeLimitReset: Int?

    // Format the output for printing from the debug console
    override public var debugDescription: String {
        let debugDescription = super.debugDescription
        let timeInfoString = ( timeBeforeLimitReset == nil ? "" : "Wait " + String(timeBeforeLimitReset!)) + " seconds before making more requests."
        return """
        \(debugDescription)
        \(timeInfoString)
        """
    }
}
